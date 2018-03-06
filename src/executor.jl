abstract type StepDefinitionMatcher end

struct Executor
    stepdefmatcher::StepDefinitionMatcher
end

struct StepExecutionResult
    v::Int
end

const NoStepDefinitionFound = StepExecutionResult(0)
const SuccessfulStepExecution = StepExecutionResult(1)

struct ScenarioResult
    steps::Vector{StepExecutionResult}
end

function executescenario(executor::Executor, scenario::Gherkin.Scenario)
    steps = if isempty(executor.stepdefmatcher.steps)
        NoStepDefinitionFound
    else
        SuccessfulStepExecution
    end
    ScenarioResult([steps])
end