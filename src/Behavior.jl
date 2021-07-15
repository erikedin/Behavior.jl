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

module Behavior

include("Gherkin.jl")
include("Selection.jl")

"Abstraction for presenting results from scenario steps."
abstract type Presenter end

"Presenting results from scenario steps as they occur."
abstract type RealTimePresenter <: Presenter end

include("stepdefinitions.jl")
include("exec_env.jl")
include("executor.jl")
include("asserts.jl")
include("presenter.jl")
include("terse_presenter.jl")
include("result_accumulator.jl")
include("engine.jl")
include("runner.jl")

export @given, @when, @then, @expect, @fail, @beforescenario, @afterscenario, runspec
export @beforefeature, @afterfeature
export suggestmissingsteps
export TerseRealTimePresenter, ColorConsolePresenter

end # module
