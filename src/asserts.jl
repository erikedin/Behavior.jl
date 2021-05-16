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

"Thrown at @expect failures in step definitions."
struct StepAssertFailure <: Exception
    assertion::String
    evaluated::String

    StepAssertFailure(assertion::String) = new(assertion, "")
    StepAssertFailure(assertion::String, evaluated::String) = new(assertion, evaluated)
end

"""
    expect(ex)

Assert that a condition `ex` is true. Throws a StepAssertFailure if false.

Warning: The expressions in the `ex` condition may be evaluated more than once,
         so only use expression without side effects in the condition.

# Examples
```
@then "this condition should hold" begin
    @expect 1 == 1
end
```

This will fail and throw a `StepAssertFailure`
```
@then "this condition should not hold" begin
    @expect 1 == 2
end
```
"""
macro expect(ex)
    comparisonops = [:(==), :(===), :(!=), :(!==)]
    iscomparison = ex.head === :call && length(ex.args) == 3 && ex.args[1] in comparisonops

    if iscomparison
        comparisonop = QuoteNode(ex.args[1])
        quote
            # Evaluate each argument separately
            local value1 = $(esc(ex.args[2]))
            local value2 = $(esc(ex.args[3]))

            # Create a en expression to show
            local showexpr = Expr(:call, $comparisonop, value1, value2)
            local msg = $(string(ex))
            local evaluated = string(showexpr)

            # Check the expectation by evaluating the original expression
            if !($(esc(ex)))
                throw(StepAssertFailure(msg, evaluated))
            end
        end
    else
        quote
            local msg = $(string(ex))
            # Check the expectation.
            if !($(esc(ex)))
                throw(StepAssertFailure(msg))
            end
        end
    end
end

"""
    @fail(message)

Fail a step with a descriptive message.
"""
macro fail(message)
    quote
        throw(StepAssertFailure($message))
    end
end