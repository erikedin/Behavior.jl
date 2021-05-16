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

using Behavior: @given, @when, @then, @expect

@given("some precondition which does nothing") do context

end

@when("we perform a no-op step") do context

end

@then("the scenario as a whole succeeds") do context

end

@when("a step has more than one matching step definition") do context

end

@when("a step has more than one matching step definition") do context

end

# This demonstrates the use of a String parameter, which will match
# more than one step.
# NOTE: At the time of writing, only String parameters are supported.
#       In the near future, one will be able to write {Int} directly,
#       and the argument `vstr` will be of type `Int` instead.
@when("foo is set to value {String}") do context, vstr
    v = parse(Int, vstr)
    context[:foo] = v
end

@then("foo is greater than zero") do context
    @expect context[:foo] > 0
end

@then("foo is less than zero") do context
    @expect context[:foo] < 0
end

@when("we need multiple lines of text") do context
    docstring = context[:block_text]
    @expect docstring == """
        This is line 1.
        This is line 2."""
end

@then("we can use doc strings like this") do context
    docstring = context[:block_text]
    @expect docstring == """
        And like
        this."""
end