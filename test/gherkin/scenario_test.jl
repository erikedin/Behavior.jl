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

using Behavior.Gherkin: issuccessful, parsescenario!, Given, When, Then, ByLineParser, ScenarioStep, ParseOptions

@testset "Scenario             " begin
    @testset "Scenario has a Given step; the parsed scenario has a Given struct" begin
        text = """
        Scenario: Some description
            Given a precondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("a precondition")]
    end

    @testset "Scenario has a When step; the parsed scenario has a When struct" begin
        text = """
        Scenario: Some description
            When some action
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[When("some action")]
    end

    @testset "Scenario has a Then step; the parsed scenario has a Then struct" begin
        text = """
        Scenario: Some description
            Then a postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Then("a postcondition")]
    end

    @testset "Scenario has an And following a Given; the And step becomes a Given" begin
        text = """
        Scenario: Some description
            Given a precondition
              And another precondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("a precondition"),
                                                 Given("another precondition")]
    end

    @testset "Scenario has an And following a When; the And step becomes a When" begin
        text = """
        Scenario: Some description
            When some action
             And another action
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[When("some action"),
                                                 When("another action")]
    end

    @testset "Scenario has an And following a Then; the And step becomes a Then" begin
        text = """
        Scenario: Some description
            Then some postcondition
             And another postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Then("some postcondition"),
                                                 Then("another postcondition")]
    end

    @testset "Blank lines" begin
        text = """
        Scenario: Some description
            Given some precondition

            When some action

            Then some postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("some precondition"),
                                             When("some action"),
                                             Then("some postcondition"),
                                             ]
    end

    @testset "But and * keywords" begin
        @testset "But follows Given/When/Then; Each But step is same as the preceding" begin
            text = """
            Scenario: Some description
                Given some precondition
                But after given
                When some action
                But after when
                Then some postcondition
                But after then
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps == ScenarioStep[Given("some precondition"),
                                                 Given("after given"),
                                                 When("some action"),
                                                 When("after when"),
                                                 Then("some postcondition"),
                                                 Then("after then")]

        end

        @testset "* follows Given/When/Then; Each * step is same as the preceding" begin
            text = """
            Scenario: Some description
                Given some precondition
                * after given
                When some action
                * after when
                Then some postcondition
                * after then
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps == ScenarioStep[Given("some precondition"),
                                                 Given("after given"),
                                                 When("some action"),
                                                 When("after when"),
                                                 Then("some postcondition"),
                                                 Then("after then")]

        end

        @testset "List items as *; Items are the same type as the preceding step" begin
            text = """
            Scenario: Some description
                Given some precondition
                * item 1
                * item 2
                * item 3
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps == ScenarioStep[Given("some precondition"),
                                                 Given("item 1"),
                                                 Given("item 2"),
                                                 Given("item 3")]

        end
    end

    @testset "Scenario is not terminated by newline; EOF is also an OK termination" begin
        text = """
        Scenario: Some description
            Then some postcondition
            And another postcondition"""

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
    end

    @testset "A given step multiple spaces before the step description; The parsed given is stripped" begin
        text = """
        Scenario: Some description
            Given      a precondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("a precondition")]
    end

    @testset "A given step multiple spaces after the step description; The parsed given is stripped" begin
        text = """
        Scenario: Some description
            Given a precondition                     
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("a precondition")]
    end

    @testset "Malformed scenarios" begin
        @testset "And as a first step; Expected Given, When, or Then before that" begin
            text = """
            Scenario: Some description
                And another postcondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :leading_and
            @test result.expected == :specific_step
            @test result.actual == :and_step
        end

        @testset "Given after a When; Expected When or Then" begin
            text = """
            Scenario: Some description
                 When some action
                Given some precondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotGiven
            @test result.actual == :Given
        end

        @testset "Given after Then; Expected Then" begin
            text = """
            Scenario: Some description
                Then some postcondition
                Given some precondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotGiven
            @test result.actual == :Given
        end

        @testset "When after Then; Expected Then" begin
            text = """
            Scenario: Some description
                Then some postcondition
                When some action
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotWhen
            @test result.actual == :When
        end

        @testset "A step definition without text; Expected a valid step definition" begin
            text = """
            Scenario: Some description
                Given
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :invalid_step
            @test result.expected == :step_definition
            @test result.actual == :invalid_step_definition
        end

        @testset "Improper scenario header; Expected valid scenario header" begin
            text = """
            Scenario malformed: This is not a proper scenario header
                Given some precondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason   == :invalid_scenario_header
            @test result.expected == :scenario_or_outline
            @test result.actual   == :invalid_header
        end
    end

    @testset "Lenient parsing" begin
        @testset "Allow arbitrary step order" begin
            @testset "Given after a When; Steps are When and Given" begin
                text = """
                Scenario: Some description
                    When some action
                    Given some precondition
                """

                byline = ByLineParser(text, ParseOptions(allow_any_step_order=true))
                result = parsescenario!(byline)

                @test issuccessful(result)
                scenario = result.value
                @test scenario.steps == ScenarioStep[When("some action"), Given("some precondition")]
            end

            @testset "When after a Then; Steps are Then and When" begin
                text = """
                Scenario: Some description
                    Then some postcondition
                    When some action
                """

                byline = ByLineParser(text, ParseOptions(allow_any_step_order=true))
                result = parsescenario!(byline)

                @test issuccessful(result)
                scenario = result.value
                @test scenario.steps == ScenarioStep[Then("some postcondition"), When("some action")]
            end

            @testset "Steps are Then/When/Given; Parse result is in that order" begin
                text = """
                Scenario: Some description
                    Then some postcondition
                    When some action
                    Given some precondition
                """

                byline = ByLineParser(text, ParseOptions(allow_any_step_order=true))
                result = parsescenario!(byline)

                @test issuccessful(result)
                scenario = result.value
                @test scenario.steps == ScenarioStep[Then("some postcondition"), When("some action"), Given("some precondition")]
            end
        end
    end

    @testset "Block text" begin
        @testset "Block text in a Given; Block text is present in step" begin
            text = """
            Scenario: Some description
                Given some precondition
                \"\"\"
                This is block text.
                There are two lines.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1].block_text == """
            This is block text.
            There are two lines."""
        end

        @testset "Another block text in a Given; Block text is present in step" begin
            text = """
            Scenario: Some description
                Given some precondition
                \"\"\"
                This is another block text.
                There are three lines.
                This is the last line.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1].block_text == """
            This is another block text.
            There are three lines.
            This is the last line."""
        end

        @testset "Block text in a When step; Block text is present in step" begin
            text = """
            Scenario: Some description
                When some action
                \"\"\"
                This is block text.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1] == When("some action"; block_text="""This is block text.""")
        end

        @testset "Block text in a Then step; Block text is present in step" begin
            text = """
            Scenario: Some description
                Then some postcondition
                \"\"\"
                This is block text.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1] == Then("some postcondition"; block_text="""This is block text.""")
        end

        @testset "Block text with a blank line; Block text is present in step" begin
            text = """
            Scenario: Some description
                Then some postcondition
                \"\"\"
                This is block text.

                This is another line.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1] == Then("some postcondition"; block_text="""This is block text.\n\nThis is another line.""")
        end
    end
end