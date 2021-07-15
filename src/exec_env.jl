# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    envdefinition = :( $ex )
    quote
        GlobalExecEnv.envs[:beforescenario] = $(esc(envdefinition))
    end
end

macro afterscenario(ex::Expr)
    envdefinition = :( $ex )
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
