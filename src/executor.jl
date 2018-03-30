struct Executor
    stepdefmatcher::StepDefinitionMatcher
    presenter::RealTimePresenter

    Executor(matcher::StepDefinitionMatcher, presenter::RealTimePresenter = QuietRealTimePresenter()) = new(matcher, presenter)
end

abstract type StepExecutionResult end

struct NoStepDefinitionFound <: StepExecutionResult end
struct SuccessfulStepExecution <: StepExecutionResult end
struct StepFailed <: StepExecutionResult end
struct UnexpectedStepError <: StepExecutionResult end
struct SkippedStep <: StepExecutionResult end

issuccess(::SuccessfulStepExecution) = true
issuccess(::StepExecutionResult) = false

struct ScenarioResult
    steps::Vector{StepExecutionResult}
    scenario::Scenario
end

function executescenario(executor::Executor, scenario::Gherkin.Scenario)
    present(executor.presenter, scenario)
    context = StepDefinitionContext()
    steps = Vector{StepExecutionResult}(length(scenario.steps))
    fill!(steps, SkippedStep())
    for i = 1:length(scenario.steps)
        present(executor.presenter, scenario.steps[i])
        present(executor.presenter, scenario.steps[1], SuccessfulStepExecution())
        steps[i] = try
            stepdefinition = findstepdefinition(executor.stepdefmatcher, scenario.steps[i])
            try
                stepdefinition.definition(context)
            catch ex
                UnexpectedStepError()
            end
        catch
            NoStepDefinitionFound()
        end
        if !issuccess(steps[i])
            break
        end
    end
    ScenarioResult(steps, scenario)
end