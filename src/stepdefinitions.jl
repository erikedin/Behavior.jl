using BDD.Gherkin


struct NoMatchingStepDefinition <: Exception end

abstract type StepDefinitionMatcher end

findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep) = error("Not implemented for abstract type StepDefinitionMatcher")

struct StepDefinition
    description::String
    definition::Function
end

#
# Global state
#

currentdefinitions = Vector{StepDefinition}()

#
# BDD macros
#

macro given(description, definition)
    quote
        push!(currentdefinitions, StepDefinition($description, () -> nothing))
    end
end

#
# Step Definition Matcher implementation
#


struct FromMacroStepDefinitionMatcher <: StepDefinitionMatcher

    function FromMacroStepDefinitionMatcher(source::AbstractString)
        include_string(source)
        new()
    end
end

function findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    matchingstepdefinitions = find(x -> x.description == step.text, currentdefinitions)
    if isempty(matchingstepdefinitions)
        throw(NoMatchingStepDefinition())
    end
    firstmatch = matchingstepdefinitions[1]
    currentdefinitions[firstmatch].definition
end