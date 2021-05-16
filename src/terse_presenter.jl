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

"""
TerseRealTimePresenter will present scenario steps only when a Scenario fails.
Otherwise it will only present scenario descriptions.

    TerseRealTimePresenter(inner::RealTimePresenter)

The `inner` presenter is used to actually print the scenarios.
"""
mutable struct TerseRealTimePresenter <: RealTimePresenter
    inner::RealTimePresenter
    currentsteps::AbstractArray{Gherkin.ScenarioStep}

    TerseRealTimePresenter(inner::RealTimePresenter) = new(inner, Gherkin.ScenarioStep[])
end

present(terse::TerseRealTimePresenter, feature::Gherkin.Feature) = present(terse.inner, feature)
function present(terse::TerseRealTimePresenter, scenario::Scenario)
    terse.currentsteps = Gherkin.ScenarioStep[]
    present(terse.inner, scenario)
end
present(terse::TerseRealTimePresenter, scenario::Scenario, ::ScenarioResult) = nothing

# Since the terse presenter shall not print any scenario steps unless they fail,
# we wait until we have a result to determine if it should be presenter or not.
# Therefore, we do nothing until we have a result.
present(::TerseRealTimePresenter, ::Gherkin.ScenarioStep) = nothing


present(terse::TerseRealTimePresenter, step::Gherkin.ScenarioStep, ::SuccessfulStepExecution) = push!(terse.currentsteps, step)
present(terse::TerseRealTimePresenter, step::Gherkin.ScenarioStep, result::SkippedStep) = present(terse.inner, step, result)

# This is a catch-all for failed steps.
function present(terse::TerseRealTimePresenter, step::Gherkin.ScenarioStep, result::StepExecutionResult)
    for step in terse.currentsteps
        present(terse.inner, step, SuccessfulStepExecution())
    end
    present(terse.inner, step, result)
end