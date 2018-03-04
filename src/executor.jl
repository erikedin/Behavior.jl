struct Executor end

struct StepExecutionResult
    v::Int
end

const NoStepDefinitionFound = StepExecutionResult(0)

struct ScenarioResult
    steps::Vector{StepExecutionResult}
end

executescenario(::Executor, ::Gherkin.Scenario) = ScenarioResult([NoStepDefinitionFound])