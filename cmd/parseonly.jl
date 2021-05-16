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

using Behavior: parseonly
using Behavior.Gherkin: ParseOptions

if length(ARGS) !== 1
    println("Usage: julia parseonly.jl <root-directory>")
    exit(1)
end

parseoptions = ParseOptions(allow_any_step_order=true)

results = parseonly(ARGS[1], parseoptions=parseoptions)
num_files = length(results)
num_success = count(x -> x.success === true, results)
if num_success === num_files
    println("All good!")
else
    num_failed = num_files - num_success
    println("Files failed parsing:")
    for rs in results
        print(rs.filename)

        if rs.success
            println(": OK")
        else
            println()
            println(" reason: ", rs.result.reason)
            println(" expected: ", rs.result.expected)
            println(" actual: ", rs.result.actual)
            println(" line $(rs.result.linenumber): $(rs.result.line)")
        end
    end
    println("Parsing failed: ", num_failed)
    println("Total number of files: ", num_files)
end