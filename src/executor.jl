abstract type StepDefinitionMatcher end

findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep) = error("Not implemented for abstract type StepDefinitionMatcher")

struct Executor
    stepdefmatcher::StepDefinitionMatcher
end

abstract type StepExecutionResult end

struct NoStepDefinitionFound <: StepExecutionResult end
struct SuccessfulStepExecution <: StepExecutionResult end
struct StepFailed <: StepExecutionResult end
struct UnexpectedStepError <: StepExecutionResult end

struct ScenarioResult
    steps::Vector{StepExecutionResult}
end

function executescenario(executor::Executor, scenario::Gherkin.Scenario)
    steps = try
        stepdefinition = findstepdefinition(executor.stepdefmatcher, scenario.steps[1])
        try
            stepdefinition()
        catch ex
            UnexpectedStepError()
        end
    catch
        NoStepDefinitionFound()
    end
    ScenarioResult([steps])
end