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

@testset "Asserts              " begin
    @testset "Assert failure; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        isfailure = false
        try
            @expect 1 == 2
        catch ex
            @test "1 == 2" == ex.assertion
            @test "1 == 2" == ex.evaluated
            isfailure = true
        end
        @test isfailure
    end

    @testset "Assert is x == y; Assertion string is 1 == 2" begin
        isfailure = false
        try
            x = 1
            y = 2
            @expect x == y
        catch ex
            @test "x == y" == ex.assertion
            @test "1 == 2" == ex.evaluated
            isfailure = true
        end
        @test isfailure
    end

    @testset "Assert is x === y; Assertion string is 1 === 2" begin
        isfailure = false
        try
            x = 1
            y = 2
            @expect x === y
        catch ex
            @test "x === y" == ex.assertion
            @test "1 === 2" == ex.evaluated
            isfailure = true
        end
        @test isfailure
    end

    @testset "Assert is x != y; Assertion string is 1 != 1" begin
        isfailure = false
        try
            x = 1
            y = 1
            @expect x != y
        catch ex
            @test "x != y" == ex.assertion
            @test "1 != 1" == ex.evaluated
            isfailure = true
        end
        @test isfailure
    end

    @testset "Assert is x !== y; Assertion string is 1 !== 1" begin
        isfailure = false
        try
            x = 1
            y = 1
            @expect x !== y
        catch ex
            @test "x !== y" == ex.assertion
            @test "1 !== 1" == ex.evaluated
            isfailure = true
        end
        @test isfailure
    end

    @testset "Assert failure in included file; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        matcher = Behavior.FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("some precondition") do context
                @expect 1 == 2
            end
        """)
        given = Gherkin.Given("some precondition")
        context = Behavior.StepDefinitionContext()

        m = Behavior.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "1 == 2"
        @test stepfailed.evaluated == "1 == 2"
    end

    @testset "Assert failure x == y in included file; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        matcher = Behavior.FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("some precondition") do context
                x = 1
                y = 2
                @expect x == y
            end
        """)
        given = Gherkin.Given("some precondition")
        context = Behavior.StepDefinitionContext()

        m = Behavior.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "x == y"
        @test stepfailed.evaluated == "1 == 2"
    end

    @testset "Assert failure in included file; Assert is isempty([1]); Failure has human readable string isempty([1])" begin
        matcher = Behavior.FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("some precondition") do context
                @expect isempty([1])
            end
        """)
        given = Gherkin.Given("some precondition")
        context = Behavior.StepDefinitionContext()

        m = Behavior.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "isempty([1])"
        @test stepfailed.evaluated == ""
    end

    @testset "Fail assertion used in step, Step is StepFailed with assertion 'Some reason'" begin
        matcher = Behavior.FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("some precondition") do context
                @fail "Some reason"
            end
        """)
        given = Gherkin.Given("some precondition")
        context = Behavior.StepDefinitionContext()

        m = Behavior.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "Some reason"
    end

end