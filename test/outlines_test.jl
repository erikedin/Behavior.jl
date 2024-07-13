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
using Behavior
using Behavior.Gherkin
using Behavior.Gherkin.Experimental
using Behavior: transformoutline

@testset "Scenario Outline     " begin
    @testset "Transform; Outline description is \"Some description\"; Result description is same" begin
        outline = ScenarioOutline("Some description", String[],
            ScenarioStep[Given("placeholder <foo>")],
            ["foo"],
            [["bar"]])

        scenarios = transformoutline(outline)

        @test scenarios[1].description == "Some description"
    end

    @testset "Transform; Outline tags are @foo @bar; Result tags are @foo @bar" begin
        outline = ScenarioOutline("", ["@foo", "@bar"],
            ScenarioStep[Given("some <foo>")],
            ["foo"],
            [["bar"]])

        scenarios = transformoutline(outline)

        @test scenarios[1].tags == ["@foo", "@bar"]
    end

    @testset "Transform; Scenario Outline has one example; One Scenario" begin
        outline = ScenarioOutline("", String[],
            ScenarioStep[Given("placeholder <foo>")],
            ["foo"],
            [["bar"]])

        scenarios = transformoutline(outline)

        @test length(scenarios) == 1
        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder bar")
    end

    @testset "Transform; Placeholder is quux; quux is replaced by example" begin
        outline = ScenarioOutline("", String[],
            ScenarioStep[Given("placeholder <quux>")],
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
    end

    @testset "Transform; Two placeholders foo, quux; foo and quux are replaced" begin
        outline = ScenarioOutline("", String[],
            ScenarioStep[Given("placeholders <foo> <quux>")],
            ["foo", "quux"],
            [["bar", "baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholders bar baz")
    end

    @testset "Transform; Steps Given and When; Both steps are transformed" begin
        steps = ScenarioStep[Given("placeholder <quux>"), When("other <quux>")]
        outline = ScenarioOutline("", String[],
            steps,
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
        @test scenario.steps[2] == When("other baz")
    end

    @testset "Transform; Steps Given and When again; Both steps are transformed" begin
        steps = ScenarioStep[Given("placeholder <quux>"), When("another step <quux>")]
        outline = ScenarioOutline("", String[],
            steps,
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
        @test scenario.steps[2] == When("another step baz")
    end

    @testset "Transform; Step Then; Step is transformed" begin
        steps = ScenarioStep[Then("step <quux>")]
        outline = ScenarioOutline("", String[],
            steps,
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Then("step baz")
    end

    @testset "Transform; Two examples; Two scenarios in the result" begin
        outline = ScenarioOutline("", String[],
            ScenarioStep[Given("step <quux>")],
            ["quux"],
            [["bar"], ["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenarios[1].steps[1] == Given("step bar")
        @test scenarios[2].steps[1] == Given("step baz")
    end

    @testset "Transform; Placeholders in the block_text; Placeholders are replaced with examples" begin
        outline = ScenarioOutline("", String[],
            [Given(""; block_text="given <quux>"),
             When(""; block_text="when <quux>"),
             Then(""; block_text="then <quux>")],
            ["quux"],
            [["bar"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenarios[1].steps[1] == Given(""; block_text="given bar")
        @test scenarios[1].steps[2] == When(""; block_text="when bar")
        @test scenarios[1].steps[3] == Then(""; block_text="then bar")
    end

    @testset "Transform; Outline examples are AbstractStrings; Interpolation works" begin
        outline = ScenarioOutline("Some description", String[],
            ScenarioStep[Given("placeholder <foo>")],
            ["foo"],
            Vector{AbstractString}[AbstractString["bar"]])

        scenarios = transformoutline(outline)

        @test scenarios[1].description == "Some description"
    end

    # TODO: Mismatching placeholders

    @testset "Issue 117: Scenario Outlines with new parser" begin
        @testset "" begin
            # Arrange
            engine = ExecutorEngine(QuietRealTimePresenter())
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("value {Int}") do context, v
                end
            """)
            addmatcher!(engine, matcher)

            source = ParserInput("""
                Feature: Scenario Outline with new parser

                    Scenario Outline: This will not run with keepgoing=true
                        Given value <v>

                    Examples:
                        |  v |
                        | 17 |
                        | 42 |
            """)
            parser = FeatureFileParser()
            parseresult = parser(source)
            feature = parseresult.value

            # Act and Assert
            # The test passes if executing the scenario does not
            # throw an exception.
            runfeature!(engine, feature; keepgoing=true)
        end
    end
end