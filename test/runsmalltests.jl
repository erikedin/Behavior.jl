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

include("selection/tag_expressions_test.jl")
include("gherkin/experimental/runtests.jl")

include("gherkin/feature_test.jl")
include("gherkin/blocktext_test.jl")

include("selection/tag_selection_test.jl")

include("executor_test.jl")
include("executor_options_test.jl")
include("executor_presentation_test.jl")
include("executor_feature_test.jl")
include("executor_datatables_test.jl")
include("step_def_test.jl")
include("result_accumulator_test.jl")
include("asserts_test.jl")
include("outlines_test.jl")
include("exec_env_test.jl")
include("variables_test.jl")
include("suggestion_test.jl")
include("rules_test.jl")