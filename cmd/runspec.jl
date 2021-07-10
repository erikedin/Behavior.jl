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

using Behavior
using Behavior.Gherkin

# In case you want a more lenient parser, you can do something like this.
# For instance, the below options allows the Given/When/Then steps to be in any order
# exitcode = runspec(; parseoptions=ParseOptions(allow_any_step_order=true)) ? 0 : - 1

const use_experimental = length(ARGS) == 1 && ARGS[1] == "--experimental"
const options = Gherkin.ParseOptions(use_experimental=use_experimental)

exitcode = runspec(parseoptions=options) ? 0 : - 1
exit(exitcode)