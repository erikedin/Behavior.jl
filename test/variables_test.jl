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

using Test
using Behavior.Gherkin: Given, When, ScenarioStep, Scenario, Background
using Behavior: FromMacroStepDefinitionMatcher, findstepdefinition

@testset "Parameters           " begin
    @testset "Matching against parameters; Definition has one String parameter; has value bar" begin
        given = Given("some bar")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using Behavior: @given

            @given("some {String}") do context, v end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["bar"]
    end
    
    @testset "Matching against parameters; Definition has one empty String parameter; has value bar" begin
        given = Given("some bar")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using Behavior: @given

            @given("some {}") do context, v end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["bar"]
    end

    @testset "Matching against parameters; Definition has one String parameter; has value baz" begin
        given = Given("some baz")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using Behavior: @given

            @given("some {String}") do context, v end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["baz"]
    end

    @testset "Matching against parameters; Definition has two String parameters;  has values bar and fnord" begin
        given = Given("some bar and fnord")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using Behavior: @given

            @given("some {String} and {String}") do context, v1, v2 end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["bar", "fnord"]
    end

    @testset "Scenario step has a variable foo; Args has :foo => bar" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using Behavior: @given

            @given("some value {String}") do context, v
                @expect v == "bar"
            end
        """)
        executor = Behavior.Executor(stepdefmatcher)

        given = Given("some value bar")
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
    end

    @testset "Scenario step has two String parameters; Arguments are bar, fnord" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using Behavior: @given

            @given("some values {} and {}") do context, v1, v2
                @expect v1 == "bar"
                @expect v2 == "fnord"
            end
        """)
        executor = Behavior.Executor(stepdefmatcher)

        given = Given("some values bar and fnord")
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
    end

    @testset "Typed parameters" begin
        @testset "Definition has one Int parameter; has value 123" begin
            given = Given("some value 123")
            stepdef_matcher = FromMacroStepDefinitionMatcher("""
                using Behavior: @given

                @given("some value {Int}") do context, v end
            """)

            stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

            @test stepdefinitionmatch.variables == [123]
        end

        @testset "Definition has one Float64 parameter; has value 234.0" begin
            given = Given("some value 234.0")
            stepdef_matcher = FromMacroStepDefinitionMatcher("""
                using Behavior: @given

                @given("some value {Float64}") do context, v end
            """)

            stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

            @test stepdefinitionmatch.variables == [234.0]
        end

        @testset "Definition has one Bool parameter; has value true" begin
            given = Given("some value true")
            stepdef_matcher = FromMacroStepDefinitionMatcher("""
                using Behavior: @given

                @given("some value {Bool}") do context, v end
            """)

            stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

            @test stepdefinitionmatch.variables == [true]
        end

        @testset "Definition has one Bool parameter; has value false" begin
            given = Given("some value false")
            stepdef_matcher = FromMacroStepDefinitionMatcher("""
                using Behavior: @given

                @given("some value {Bool}") do context, v end
            """)

            stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

            @test stepdefinitionmatch.variables == [false]
        end

        @testset "Definition has one Bool parameter; has value false" begin
            given = Given("some value false")
            stepdef_matcher = FromMacroStepDefinitionMatcher("""
                using Behavior: @given

                @given("some value {Bool}") do context, v end
            """)

            stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

            @test stepdefinitionmatch.variables == [false]
        end
    end
end