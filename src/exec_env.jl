abstract type ExecutionEnvironment end

struct NoExecutionEnvironment <: ExecutionEnvironment end
beforescenario(::NoExecutionEnvironment, ::StepDefinitionContext, ::Gherkin.Scenario) = nothing
afterscenario(::NoExecutionEnvironment, ::StepDefinitionContext, ::Gherkin.Scenario) = nothing

struct FromSourceExecutionEnvironment <: ExecutionEnvironment
    source::String
end

