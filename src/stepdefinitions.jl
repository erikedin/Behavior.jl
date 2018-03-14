using BDD.Gherkin

struct NoMatchingStepDefinition <: Exception end

abstract type StepDefinitionMatcher end

findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep) = error("Not implemented for abstract type StepDefinitionMatcher")

struct FromMacroStepDefinitionMatcher <: StepDefinitionMatcher

    function FromMacroStepDefinitionMatcher(source::AbstractString)
        new()
    end
end

function findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    if step.text == "some definition"
        () -> nothing
    else
        throw(NoMatchingStepDefinition())
    end
end