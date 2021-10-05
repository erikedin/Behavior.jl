# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

using Behavior.Gherkin

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


#
# Matching utilities
#

"""
    symbolwithdefault(s::AbstractString) :: Symbol

If the string `s` is empty, then it returns the `:String` symbol. Otherwise
it returns `Symbol(s)`.

This function simply encapsulates the fact that an empty parameter `{}` in a
step defaults to the `String` type.
"""
function symbolwithdefault(s::AbstractString) :: Symbol
    if s == ""
        :String
    else
        Symbol(s)
    end
end

function makedescriptionregex(s::String) :: Tuple{Regex, AbstractVector{Symbol}}
    variablematches = eachmatch(r"{([^{}]*)}", s)
    # The variables here are the variable types if the step has parameters.
    # So if the step is
    #   Given some value {Int} and some text {String}
    # the `variables` will hold [:Int, :String]
    variables = [symbolwithdefault(m[1]) for m in variablematches]

    # Escaping the string here so that characters that have meaning in a regular expressios
    # is treated as their actual character, instead of as regular expression characters.
    # The escaped characters are the PCRE metacharacters.
    escaped_s = escape_string(s, "\$^()|.[]?*+")

    # Replace variables like {foo} with a regex expression for that
    # variable like (?<foo>.*)
    regex_s = replace(escaped_s, r"{([^{}]*)}" => s"(.*)")

    Regex("^$(regex_s)\$"), variables
end

"A step definition has a description, which is used to find it, a function to execute, and a location."
struct StepDefinition
    description::String
    descriptionregex::Regex
    definition::Function
    location::StepDefinitionLocation
    variabletypes::Vector{Symbol}

    function StepDefinition(description::String, definition::Function, location::StepDefinitionLocation)
        descriptionregex, variables = makedescriptionregex(description)
        new(description, descriptionregex, definition, location, variables)
    end
end

struct StepDefinitionMatch
    stepdefinition::StepDefinition
    variables::Vector{Any}

    StepDefinitionMatch(s::StepDefinition) = new(s, Any[])
    function StepDefinitionMatch(s::StepDefinition, variables::AbstractArray{<:Any})
        new(s, variables)
    end
end

"""
The context in which a step definition executes. This context is used to share data between
different step definitions. It is created newly for each scenario. Thus, two scenarios cannot share
data.
"""
mutable struct StepDefinitionContext
    storage::Dict{Symbol, Any}
    datatable::Gherkin.DataTable

    StepDefinitionContext() = new(Dict{Symbol, Any}(), Gherkin.DataTable())
end

"Find a variable value given a symbol name."
Base.getindex(context::StepDefinitionContext, sym::Symbol) = context.storage[sym]

"Set a variable value given a symbol name and a value."
Base.setindex!(context::StepDefinitionContext, value::Any, sym::Symbol) = context.storage[sym] = value

"Check for a mapping for a given key"
Base.haskey(context::StepDefinitionContext, sym::Symbol) = haskey(context.storage, sym)

#
# Global state
#

currentdefinitions = Vector{StepDefinition}()
currentfilename = ""

#
# Step definition macros
#

function step_definition_(definition::Expr, description::String)
    # The step definition function takes a context and executes a bit of code supplied by the
    # test writer. The bit of code is in $definition.
    definitionfunction = :((context, vars) -> $definition(context, vars...))
    descriptionregex = makedescriptionregex(description)
    quote
        # Push a given step definition to the global state so it can be found by the
        # `StepDefinitionMatcher`.
        push!(currentdefinitions,
            StepDefinition(
                $description,
                (context, vars) -> begin
                try
                    # Escape the step definition code so it gets the proper scope.
                    $(esc(definitionfunction))(context, vars)
                    # Any step definition that does not throw an exception is successful.
                    SuccessfulStepExecution()
                catch ex
                    # StepAssertFailures are turned into a failed result here, but all other exceptions
                    # are propagated.
                    if ex isa StepAssertFailure
                        StepFailed(ex.assertion, ex.evaluated)
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
        include_string(Main, source, filename)
        # Save the step definitions found in the global variable `currentdefinitions` into a local
        # variable, so that we can clear the global state and read another file.
        mydefinitions = currentdefinitions
        this = new(mydefinitions, filename)
        currentdefinitions = Vector{StepDefinition}()
        this
    end
end

"""
    converttypes(typesymbol::Symbol, value) :: Any

Convert `value` to the type named by `typesymbol`.
This is necessary because `Number` types are converted from strings to its primitive
type using the `parse` method, while other types are converted from strings using the
`convert` method.

# Example
```julia-repl
julia> converttypes(:Int, "123")
123
```
"""
function converttypes(typesymbol::Symbol, value) :: Any
    t = eval(typesymbol)
    if t <: Number
        parse(t, value)
    else
        convert(t, value)
    end
end

function matchdefinition(stepdefinition::StepDefinition, description::String) :: Union{StepDefinitionMatch,Nothing}
    m = match(stepdefinition.descriptionregex, description)
    if m !== nothing
        variablestrings = String[String(x) for x in m.captures]
        # Combine the parameter values captured in m with their types, that
        # we have from the stepdefinition.
        varswithtypes = zip(stepdefinition.variabletypes, variablestrings)
        # Convert each parameter value to its expected type.
        # Example: if `varswithtypes = [(:Int, "17"), (:Bool, "true")]`
        # then `variables` will be `[17, true]`.
        variables = [converttypes(typesymbol, value)
                     for (typesymbol, value) in varswithtypes]
        StepDefinitionMatch(stepdefinition, variables)
    else
        nothing
    end
end

"""
    findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)

Find a step definition that has a description that matches the provided scenario step.
If no such step definition is found, throw a `NoMatchingStepDefinition`.
If more than one such step definition is found, throw a `NonUniqueStepDefinition`.
"""
function findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep) :: StepDefinitionMatch
    allsteps = map(x -> matchdefinition(x, step.text), matcher.stepdefinitions)
    matches = filter(x -> x !== nothing, allsteps)
    if isempty(matches)
        throw(NoMatchingStepDefinition())
    end
    if length(matches) > 1
        locations = map(m -> StepDefinitionLocation(matcher.filename, 0),
                        matches)
        throw(NonUniqueStepDefinition(locations))
    end
    matches[1]
end

#
# Composite matcher
#
"""
Find step definitions from multiple other step definition matchers.
"""
mutable struct CompositeStepDefinitionMatcher <: StepDefinitionMatcher
    matchers::Vector{StepDefinitionMatcher}

    CompositeStepDefinitionMatcher(matchers...) = new([matchers...])
end

function findstepdefinition(composite::CompositeStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    matching = StepDefinitionMatch[]
    nonuniquesfound = StepDefinitionLocation[]
    # Recursively call `findstepdefinition(...)` on all sub-matchers.
    # When they throw a `NonUniqueStepDefinition`, record the location so it can be shown to the
    # user where the step definitions are.
    # Ignore `NonUniqueStepDefinition` exceptions, as normally all but one of the matchers will
    # throw it.
    for matcher in composite.matchers
        try
            stepdefinitionmatch = findstepdefinition(matcher, step)
            push!(matching, stepdefinitionmatch)
        catch ex
            if ex isa NonUniqueStepDefinition
                append!(nonuniquesfound, ex.locations)
            end
        end
    end
    if length(matching) > 1 || !isempty(nonuniquesfound)
        locations = vcat(nonuniquesfound, [d.stepdefinition.location for d in matching])
        throw(NonUniqueStepDefinition(locations))
    end
    if isempty(matching)
        throw(NoMatchingStepDefinition())
    end
    matching[1]
end

function addmatcher!(composite::CompositeStepDefinitionMatcher, matcher::StepDefinitionMatcher)
    push!(composite.matchers, matcher)
end