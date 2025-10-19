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

        @testset "Scenario; Long  description without a newline before Given; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some description
                    This is a long description.
                    Given some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.long_description == "This is a long description."
            @test result.value.steps == [Given("some precondition")]
        end

        @testset "Scenario; Long description without any steps; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some description
                    This is a long description.
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.long_description == "This is a long description."
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

        @testset "Scenario; Given has leading spaces in the description; The leading spaces are ignored" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given     some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition")]
        end

        # TODO Investigate if the official cucumber allows this.
        # @testset "Scenario; Given has no description; Not OK" begin
        #     # Arrange
        #     input = ParserInput("""
        #         Scenario: Some new description
        #             Given
        #     """)

        #     # Act
        #     parser = ScenarioParser()
        #     result = parser(input)

        #     # Assert
        #     @test result isa BadParseResult{Scenario}
        # end

        @testset "Scenario; Malformed keyword; Not OK" begin
            # Arrange
            input = ParserInput("""
                Scenario malform: Some new description
                    Given some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Scenario}
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

        @testset "Scenario; Blank line between steps; OK" begin
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

        @testset "Scenario: Block text has multiple lines; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        \"\"\"
                        Block text line 1.
                        Block text line 2.
                        \"\"\"
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [
                Given("some precondition"; block_text="Block text line 1.\nBlock text line 2.")
            ]
        end

        @testset "Scenario: Block text has a blank line; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Given some precondition
                        \"\"\"
                        Block text line 1.

                        Block text line 2.
                        \"\"\"
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [
                Given("some precondition"; block_text="Block text line 1.\n\nBlock text line 2.")
            ]
        end

        @testset "Scenario: Block text on a when step; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    When some action
                        \"\"\"
                        Block text line.
                        \"\"\"
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [
                When("some action"; block_text="Block text line.")
            ]
        end

        @testset "Scenario: Block text on a then step; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Then some postcondition
                        \"\"\"
                        Block text line.
                        \"\"\"
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.steps == [
                Then("some postcondition"; block_text="Block text line.")
            ]
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

        @testset "Scenario Outlines; One placeholder is empty; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline: Some scenario outline

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Scenarios:
                        | Foo   | Bar     |
                        | baz   ||
                        | fnord | quuxbaz |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.examples[1] == ["baz", ""]
            @test result.value.examples[2] == ["fnord", "quuxbaz"]
        end

        @testset "Scenario Outlines; The placeholder values are digits; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline: Some scenario outline

                    Given some value <Foo>
                     When some action
                     Then some postcondition

                    Scenarios:
                        | Foo | Bar     |
                        | 1   | 2       |
                        | 3   | 4       |
            """)

            # Act
            parser = ScenarioOutlineParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{ScenarioOutline}
            @test result.value.examples[1] == ["1", "2"]
            @test result.value.examples[2] == ["3", "4"]
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