using ExecutableSpecifications.Gherkin
import Base.==

struct StepDefinitionLocation
    filename::String
    lineno::Int
end
==(a::StepDefinitionLocation, b::StepDefinitionLocation) = a.filename == b.filename && a.lineno == b.lineno

struct NoMatchingStepDefinition <: Exception end
struct NonUniqueStepDefinition <: Exception
    locations::Vector{StepDefinitionLocation}
end

abstract type StepDefinitionMatcher end

# A StepDefinitionMatcher should define a method
# findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep)

struct StepDefinition
    description::String
    definition::Function
end

#
# Step definition context
#
struct StepDefinitionContext
    variables::Dict{Symbol, Any}

    StepDefinitionContext() = new(Dict{Symbol, Any}())
end

Base.getindex(context::StepDefinitionContext, sym::Symbol) = context.variables[sym]
Base.setindex!(context::StepDefinitionContext, value::Any, sym::Symbol) = context.variables[sym] = value

#
# Global state
#

currentdefinitions = Vector{StepDefinition}()

#
# Step definition macros
#

function step_definition_(description::String, definition::Expr)
    quote
        push!(currentdefinitions, StepDefinition($description, (context) -> begin
            try
                $definition
                SuccessfulStepExecution()
            catch ex
                if ex isa StepAssertFailure
                    StepFailed()
                else
                    rethrow()
                end
            end
        end))
    end
end

macro given(description, definition)
    step_definition_(description, definition)
end

macro when(description, definition)
    step_definition_(description, definition)
end

macro then(description, definition)
    step_definition_(description, definition)
end

#
# Step Definition Matcher implementation
#

struct FromMacroStepDefinitionMatcher <: StepDefinitionMatcher
    stepdefinitions::Vector{StepDefinition}
    filename::String

    function FromMacroStepDefinitionMatcher(source::AbstractString; filename::String="<no filename>")
        global currentdefinitions
        include_string(source)
        mydefinitions = currentdefinitions
        this = new(mydefinitions, filename)
        currentdefinitions = Vector{StepDefinition}()
        this
    end
end

function findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    matchingindexes = find(x -> x.description == step.text, matcher.stepdefinitions)
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
struct CompositeStepDefinitionMatcher <: StepDefinitionMatcher
    matchers::Vector{StepDefinitionMatcher}

    CompositeStepDefinitionMatcher(matchers...) = new([matchers...])
end

function findstepdefinition(composite::CompositeStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    for m in composite.matchers
        try
            stepdefinition = findstepdefinition(m, step)
            return stepdefinition
        end
    end
end