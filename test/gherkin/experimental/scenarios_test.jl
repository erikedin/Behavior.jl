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

using Behavior.Gherkin.Experimental: eofP

@testset "Gherkin Scenarios    " begin
    @testset "Scenario parser" begin
        @testset "Empty Scenario, no description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario:
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == ""
            @test result.value.steps == []
        end

        @testset "Empty Scenario, some description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some description
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some description"
            @test result.value.steps == []
        end

        @testset "Scenario Outline:, Not OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline:
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Scenario}
        end

        @testset "Two givens, Some new description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                    Given some other precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition"), Given("some other precondition")]
        end

        @testset "Given/When/Then; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                     When some action
                     Then some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition"), When("some action"), Then("some precondition")]
        end

        @testset "When/Then; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                     When some action
                     Then some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [When("some action"), Then("some precondition")]
        end

        @testset "Then; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                     Then some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Then("some precondition")]
        end

        @testset "Two givens with a block text, Some new description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        \"\"\"
                        Block text line.
                        \"\"\"
                    Given some other precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [
                Given("some precondition"; block_text="Block text line."),
                Given("some other precondition")]
        end

        @testset "A step has a data table; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        | Foo | Bar  |
                        | Baz | Quux |
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            given = result.value.steps[1]
            @test given.text == "some precondition"
            @test given.datatable == [
                ["Foo", "Bar"],
                ["Baz", "Quux"]
            ]
        end

        @testset "A step has a data table and a block text; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        | Foo | Bar  |
                        | Baz | Quux |
                        \"\"\"
                        Some block text
                        \"\"\"
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            given = result.value.steps[1]
            @test given.text == "some precondition"
            @test given.datatable == [
                ["Foo", "Bar"],
                ["Baz", "Quux"]
            ]
            @test given.block_text == "Some block text"
        end

        @testset "A step has block text and data table; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        \"\"\"
                        Some block text
                        \"\"\"
                        | Foo | Bar  |
                        | Baz | Quux |
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            given = result.value.steps[1]
            @test given.text == "some precondition"
            @test given.datatable == [
                ["Foo", "Bar"],
                ["Baz", "Quux"]
            ]
            @test given.block_text == "Some block text"
        end
    end

    @testset "RuleParser" begin
        @testset "Empty Rule, no description; OK" begin
            # Arrange
            input = ParserInput("""
                Rule:
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == ""
            @test result.value.scenarios == []
        end

        @testset "Empty Rule, Some rule description; OK" begin
            # Arrange
            input = ParserInput("""
                Rule: Some rule description
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == "Some rule description"
            @test result.value.scenarios == []
        end

        @testset "Rule with one scenario; OK" begin
            # Arrange
            input = ParserInput("""
                Rule: Some rule description
                    Scenario: Some scenario
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == "Some rule description"
            @test result.value.scenarios[1].description == "Some scenario"
        end

        @testset "Rule with two scenarios; OK" begin
            # Arrange
            input = ParserInput("""
                Rule: Some rule description
                    Scenario: Some scenario
                    Scenario: Some other scenario
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == "Some rule description"
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[2].description == "Some other scenario"
        end

        @testset "Rule with two scenarios any steps; OK" begin
            # Arrange
            input = ParserInput("""
                Rule: Some rule description
                    Scenario: Some scenario
                        Given some precondition
                        Given some other precondition
                    Scenario: Some other scenario
                        Given some third precondition
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == "Some rule description"
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[1].steps == [
                Given("some precondition"), Given("some other precondition")
            ]
            @test result.value.scenarios[2].description == "Some other scenario"
            @test result.value.scenarios[2].steps == [
                Given("some third precondition")
            ]
        end

        @testset "Rule with two scenarios any steps separated by blank lines; OK" begin
            # Arrange
            input = ParserInput("""
                Rule: Some rule description

                    Scenario: Some scenario
                        Given some precondition
                        Given some other precondition

                    Scenario: Some other scenario
                        Given some third precondition
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == "Some rule description"
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[1].steps == [
                Given("some precondition"), Given("some other precondition")
            ]
            @test result.value.scenarios[2].description == "Some other scenario"
            @test result.value.scenarios[2].steps == [
                Given("some third precondition")
            ]
        end
    end

    @testset "Scenario Outlines" begin
        @testset "Scenario Outline one step, no description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline:
                    Given some value <Foo>

                    Examples:
                        | Foo |
                        | bar |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.description == ""
            @test result.value.tags == []
            @test result.value.steps == [Given("some value <Foo>")]
            @test result.value.placeholders == ["Foo"]
            @test result.value.examples == [["bar"]]
        end

        @testset "Scenario Outline, then EOF; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline:
                    Given some value <Foo>

                    Examples:
                        | Foo |
                        | bar |
            """)

            # Act
            parser = Sequence{Union{ScenarioOutline, Nothing}}(
                        ScenarioOutlineParser(),
                        eofP)
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{Union{ScenarioOutline, Nothing}}}
            @test result.value[1].description == ""
            @test result.value[1].steps == [Given("some value <Foo>")]
            @test result.value[1].placeholders == ["Foo"]
            @test result.value[1].examples == [["bar"]]
            @test result.value[2] === nothing
        end

        @testset "Scenario Outline one step, and a description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline: Some scenario outline
                    Given some value <Foo>

                    Examples:
                        | Foo |
                        | bar |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.description == "Some scenario outline"
        end

        @testset "Scenario Outline with tags; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline
                    Given some value <Foo>

                    Examples:
                        | Foo |
                        | bar |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.tags == ["@tag1", "@tag2"]
        end

        @testset "Scenario Outline with Given/When/Then; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline
                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Examples:
                        | Foo |
                        | bar |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.steps == [
                Given("some value <Foo>"),
                 When("some action"),
                 Then("some postcondition")
            ]
        end

        @testset "Scenario Outline a longer description; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline

                    This is a long description.
                    On two lines.

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Examples:
                        | Foo |
                        | bar |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.long_description == "This is a long description.\nOn two lines."
        end

        @testset "Scenario Outline with two placeholders; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Examples:
                        | Foo | Bar  |
                        | baz | quux |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.placeholders == ["Foo", "Bar"]
        end

        @testset "Scenario Outline with two columns of examples; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Examples:
                        | Foo | Bar  |
                        | baz | quux |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.examples[1] == ["baz", "quux"]
        end

        @testset "Scenario Outline with two rows of examples; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Examples:
                        | Foo   | Bar     |
                        | baz   | quux    |
                        | fnord | quuxbaz |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.examples[1] == ["baz", "quux"]
            @test result.value.examples[2] == ["fnord", "quuxbaz"]
        end

        @testset "Scenario Outline with two rows of Scenarios instead of Examples; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                Scenario Outline: Some scenario outline

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Scenarios:
                        | Foo   | Bar     |
                        | baz   | quux    |
                        | fnord | quuxbaz |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.examples[1] == ["baz", "quux"]
            @test result.value.examples[2] == ["fnord", "quuxbaz"]
        end
    end

    @testset "And/But*" begin
        @testset "Scenario has an And; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                      And some other precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition"), And("some other precondition")]
        end

        @testset "Scenario has a But; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                      But some other precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition"), And("some other precondition")]
        end

        @testset "Scenario has a *; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        * some other precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition"), And("some other precondition")]
        end
    end
end