abstract type ExecutionEnvironment end


struct NoExecutionEnvironment <: ExecutionEnvironment end
beforescenario(::NoExecutionEnvironment, ::StepDefinitionContext, ::Gherkin.Scenario) = nothing
afterscenario(::NoExecutionEnvironment, ::StepDefinitionContext, ::Gherkin.Scenario) = nothing

module GlobalExecEnv
    envs = Dict{Symbol, Function}()

    function clear()
        global envs
        envs = Dict{Symbol, Function}()
    end
end

macro beforescenario(ex::Expr)
    envdefinition = :( (context, scenario) -> $ex )
    quote
        GlobalExecEnv.envs[:beforescenario] = $(esc(envdefinition))
    end
end

struct FromSourceExecutionEnvironment <: ExecutionEnvironment
    envdefinitions::Dict{Symbol, Function}

    function FromSourceExecutionEnvironment(source::String)
        include_string(Main, source)

        this = new(GlobalExecEnv.envs)
        GlobalExecEnv.clear()
        this
    end
end

function beforescenario(
        executionenv::FromSourceExecutionEnvironment,
        context::StepDefinitionContext,
        scenario::Gherkin.Scenario)

    if haskey(executionenv.envdefinitions, :beforescenario)
        executionenv.envdefinitions[:beforescenario](context, scenario)
    end
end
