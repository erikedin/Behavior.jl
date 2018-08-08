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

macro afterscenario(ex::Expr)
    envdefinition = :( (context, scenario) -> $ex )
    quote
        GlobalExecEnv.envs[:afterscenario] = $(esc(envdefinition))
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

function invokeenvironmentmethod(
        executionenv::FromSourceExecutionEnvironment,
        context::StepDefinitionContext,
        scenario::Gherkin.Scenario,
        methodsym::Symbol)

    if haskey(executionenv.envdefinitions, methodsym)
        method = executionenv.envdefinitions[methodsym]
        Base.invokelatest(method, context, scenario)
    end
end

beforescenario(executionenv::FromSourceExecutionEnvironment,
               context::StepDefinitionContext,
               scenario::Gherkin.Scenario) = invokeenvironmentmethod(executionenv, context, scenario, :beforescenario)

afterscenario(executionenv::FromSourceExecutionEnvironment,
              context::StepDefinitionContext,
              scenario::Gherkin.Scenario) = invokeenvironmentmethod(executionenv, context, scenario, :afterscenario)
