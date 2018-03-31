struct Executor
    stepdefmatcher::StepDefinitionMatcher
    presenter::RealTimePresenter

    Executor(matcher::StepDefinitionMatcher, presenter::RealTimePresenter = QuietRealTimePresenter()) = new(matcher, presenter)
end

abstract type StepExecutionResult end

struct NoStepDefinitionFound <: StepExecutionResult end
struct NonUniqueMatch <: StepExecutionResult end
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
    lastexecutedstep = 0

    # Find a unique step definition for each step and execute it.
    # Present each step, first as it is about to be executed, and then once more with the result.
    for i = 1:length(scenario.steps)
        present(executor.presenter, scenario.steps[i])
        steps[i] = try
            stepdefinition = findstepdefinition(executor.stepdefmatcher, scenario.steps[i])
            try
                stepdefinition.definition(context)
            catch ex
                UnexpectedStepError()
            end
        catch ex
            if ex isa NoMatchingStepDefinition
                NoStepDefinitionFound()
            elseif ex isa NonUniqueStepDefinition
                NonUniqueMatch()
            else
                rethrow(ex)
            end
        end
        present(executor.presenter, scenario.steps[i], steps[i])
        lastexecutedstep = i
        if !issuccess(steps[i])
            break
        end
    end

    # Present any remaining steps as skipped.
    for k = lastexecutedstep + 1:length(scenario.steps)
        present(executor.presenter, scenario.steps[k])
        present(executor.presenter, scenario.steps[k], steps[k])
    end

    ScenarioResult(steps, scenario)
end

struct FeatureResult
    scenarioresults::Vector{ScenarioResult}
end

function executefeature(executor::Executor, feature::Gherkin.Feature)
    present(executor.presenter, feature)
    scenarioresults = [executescenario(executor, s) for s in feature.scenarios]
    FeatureResult(scenarioresults)
end