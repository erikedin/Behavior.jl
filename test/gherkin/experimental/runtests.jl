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

using Behavior.Gherkin.Experimental
using Behavior.Gherkin.Experimental: BadExpectedEOFParseResult, BadUnexpectedEOFParseResult, And
using Behavior.Gherkin: Given, When, Then, Scenario, Feature, ScenarioStep, Background
using Behavior.Gherkin: DataTable, ScenarioOutline
using Test

include("combinators_test.jl")
include("charP_test.jl")
include("eofP_test.jl")
include("repeatC_test.jl")
include("escapeP_test.jl")
include("satisfyC_test.jl")
include("to_test.jl")
include("pipe_test.jl")
include("choiceC_test.jl")
include("manyC_test.jl")
include("sequenceC_test.jl")
include("optionalC_test.jl")
include("literalC_test.jl")
include("commentP_test.jl")
include("datatableP_test.jl")
include("gherkin_combinators_test.jl")
include("scenarios_test.jl")
include("featurefile_test.jl")