using ExecutableSpecifications.Gherkin

"""
The location of a step definition (the Julia code of a test) is a filename and a line number.
"""
struct StepDefinitionLocation
    filename::String
    lineno::Int
end

"Thrown if there is no step definition matching a scenario step."
struct NoMatchingStepDefinition <: Exception end

"Thrown when more than one step definition matches a scenario step."
struct NonUniqueStepDefinition <: Exception
    locations::Vector{StepDefinitionLocation}
end

"A step definition matcher takes a scenario step and finds a matching step definition to execute."
abstract type StepDefinitionMatcher end

# A StepDefinitionMatcher should define a method
# findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep)

"A step definition has a description, which is used to find it, a function to execute, and a location."
struct StepDefinition
    description::String
    definition::Function
    location::StepDefinitionLocation
end


"""
The context in which a step definition executes. This context is used to share data between
different step definitions. It is created newly for each scenario. Thus, two scenarios cannot share
data.
"""
struct StepDefinitionContext
    variables::Dict{Symbol, Any}

    StepDefinitionContext() = new(Dict{Symbol, Any}())
end

"Find a variable value given a symbol name."
Base.getindex(context::StepDefinitionContext, sym::Symbol) = context.variables[sym]

"Set a variable value given a symbol name and a value."
Base.setindex!(context::StepDefinitionContext, value::Any, sym::Symbol) = context.variables[sym] = value

#
# Global state
#

currentdefinitions = Vector{StepDefinition}()
currentfilename = ""

#
# Step definition macros
#

function step_definition_(description::String, definition::Expr)
    # The step definition function takes a context and executes a bit of code supplied by the
    # test writer. The bit of code is in $definition.
    definitionfunction = :(context -> $definition)
    quote
        # Push a given step definition to the global state so it can be found by the
        # `StepDefinitionMatcher`.
        push!(currentdefinitions, StepDefinition($description, (context) -> begin
                try
                    # Escape the step definition code so it gets the proper scope.
                    $(esc(definitionfunction))(context)
                    # Any step definition that does not throw an exception is successful.
                    SuccessfulStepExecution()
                catch ex
                    # StepAssertFailures are turned into a failed result here, but all other exceptions
                    # are propagated.
                    if ex isa StepAssertFailure
                        StepFailed(ex.assertion)
                    else
                        rethrow()
                    end
                end
            end,
            StepDefinitionLocation(currentfilename, 0)))
    end
end

"Provide a more user friendly @given macro for a step definition."
macro given(description, definition)
    step_definition_(description, definition)
end

"Provide a more user friendly @when macro for a step definition."
macro when(description, definition)
    step_definition_(description, definition)
end

"Provide a more user friendly @then macro for a step definition."
macro then(description, definition)
    step_definition_(description, definition)
end

#
# Step Definition Matcher implementation
#

"""
Finds step definitions defined in a Julia file with the @given, @when, @then macros defined above.
Takes a source text as input and reads the code defined in it.
"""
struct FromMacroStepDefinitionMatcher <: StepDefinitionMatcher
    stepdefinitions::Vector{StepDefinition}
    filename::String

    function FromMacroStepDefinitionMatcher(source::AbstractString; filename::String="<no filename>")
        global currentdefinitions
        global currentfilename
        currentfilename = filename
        # Read all step definitions as Julia code.
        include_string(Main, source)
        # Save the step definitions found in the global variable `currentdefinitions` into a local
        # variable, so that we can clear the global state and read another file.
        mydefinitions = currentdefinitions
        this = new(mydefinitions, filename)
        currentdefinitions = Vector{StepDefinition}()
        this
    end
end

"""
    findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)

Find a step definition that has a description that matches the provided scenario step.
If no such step definition is found, throw a `NoMatchingStepDefinition`.
If more than one such step definition is found, throw a `NonUniqueStepDefinition`.
"""
function findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    matchingindexes = findall(x -> x.description == step.text, matcher.stepdefinitions)
    matchingstepdefinitions = [matcher.stepdefinitions[i] for i in matchingindexes]
    if isempty(matchingstepdefinitions)
        throw(NoMatchingStepDefinition())
    end
    if length(matchingstepdefinitions) > 1
        locations = map(stepdefinition -> StepDefinitionLocation(matcher.filename, 0),
                        matchingstepdefinitions)
        throw(NonUniqueStepDefinition(locations))
    end
    matchingstepdefinitions[1]
end

#
# Composite matcher
#
"""
Find step definitions from multiple other step definition matchers.
"""
struct CompositeStepDefinitionMatcher <: StepDefinitionMatcher
    matchers::Vector{StepDefinitionMatcher}

    CompositeStepDefinitionMatcher(matchers...) = new([matchers...])
end

function findstepdefinition(composite::CompositeStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    matching = StepDefinition[]
    nonuniquesfound = StepDefinitionLocation[]
    # Recursively call `findstepdefinition(...)` on all sub-matchers.
    # When they throw a `NonUniqueStepDefinition`, record the location so it can be shown to the
    # user where the step definitions are.
    # Ignore `NonUniqueStepDefinition` exceptions, as normally all but one of the matchers will
    # throw it.
    for m in composite.matchers
        try
            stepdefinition = findstepdefinition(m, step)
            push!(matching, stepdefinition)
        catch ex
            if ex isa NonUniqueStepDefinition
                append!(nonuniquesfound, ex.locations)
            end
        end
    end
    if length(matching) > 1 || !isempty(nonuniquesfound)
        locations = vcat(nonuniquesfound, [d.location for d in matching])
        throw(NonUniqueStepDefinition(locations))
    end
    if isempty(matching)
        throw(NoMatchingStepDefinition())
    end
    matching[1]
end