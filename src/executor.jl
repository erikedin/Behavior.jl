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
struct SkippedStep <: StepExecutionResult end

struct ScenarioResult
    steps::Vector{StepExecutionResult}
end

function executescenario(executor::Executor, scenario::Gherkin.Scenario)
    steps = Vector{StepExecutionResult}(length(scenario.steps))
    fill!(steps, SkippedStep())
    for i = 1:length(scenario.steps)
        try
            stepdefinition = findstepdefinition(executor.stepdefmatcher, scenario.steps[1])
            try
                steps[i] = stepdefinition()
            catch ex
                steps[i] = UnexpectedStepError()
                break
            end
        catch
            steps[i] = NoStepDefinitionFound()
            break
        end
    end
    ScenarioResult(steps)
end