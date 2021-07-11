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

using Behavior: suggestmissingsteps, ParseOptions

if length(ARGS) !== 2 && length(ARGS) !== 3
    println("Usage: julia suggeststeps.jl <feature file> <steps root path> [--experimental]")
    exit(1)
end

featurefile = ARGS[1]
stepsrootpath = ARGS[2]

const use_experimental = length(ARGS) == 3 && ARGS[3] == "--experimental"

parseoptions = ParseOptions(allow_any_step_order=true, use_experimental=use_experimental)

suggestmissingsteps(featurefile, stepsrootpath, parseoptions=parseoptions)