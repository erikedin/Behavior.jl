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

@testset "Gherkin combinators  " begin
    @testset "Block text" begin
        @testset "Empty; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                \"\"\"
            """)
            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == ""
        end

        @testset "Empty, then Quux; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                \"\"\"
                Quux
            """)
            # Act
            p = Sequence{String}(BlockText(), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["", "Quux"]
        end

        @testset "Foo; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                \"\"\"
            """)
            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Foo Bar Baz; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                Bar
                Baz
                \"\"\"
            """)
            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo\nBar\nBaz"
        end

        @testset "Foo Bar Baz, then Quux; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                Bar
                Baz
                \"\"\"
                Quux
            """)
            # Act
            p = Sequence{String}(BlockText(), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Foo\nBar\nBaz", "Quux"]
        end
    end

    @testset "KeywordParser" begin
        @testset "Scenario:, Scenario:; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario:
            """)

            # Act
            parser = KeywordParser("Scenario:")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Keyword}
            @test result.value.keyword == "Scenario:"
            @test result.value.rest == ""
        end

        @testset "Given, Given; OK" begin
            # Arrange
            input = ParserInput("""
                Given
            """)

            # Act
            parser = KeywordParser("Given")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Keyword}
            @test result.value.keyword == "Given"
            @test result.value.rest == ""
        end

        @testset "Scenario:, Scenario Outline:; Not OK" begin
            # Arrange
            input = ParserInput("""
                Scenario Outline:
            """)

            # Act
            parser = KeywordParser("Scenario:")
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Keyword}
        end

        @testset "Scenario: then Scenario Outline:, Scenario:, Scenario Outline:; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario:
                Scenario Outline:
            """)

            # Act
            parser = Sequence{Keyword}(KeywordParser("Scenario:"), KeywordParser("Scenario Outline:"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{Keyword}}
            @test result.value[1].keyword == "Scenario:"
            @test result.value[1].rest == ""
            @test result.value[2].keyword == "Scenario Outline:"
            @test result.value[2].rest == ""
        end

        @testset "Scenario:, Scenario: Some description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some description
            """)

            # Act
            parser = KeywordParser("Scenario:")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Keyword}
            @test result.value.keyword == "Scenario:"
            @test result.value.rest == "Some description"
        end

        @testset "Scenario:, Scenario:Some description, without a space; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario:Some description
            """)

            # Act
            parser = KeywordParser("Scenario:")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Keyword}
            @test result.value.keyword == "Scenario:"
            @test result.value.rest == "Some description"
        end

        @testset "Given; Given on the description as well; Only first given is removed" begin
            # Arrange
            input = ParserInput("""
                Given Given
            """)

            # Act
            parser = KeywordParser("Given")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Keyword}
            @test result.value.keyword == "Given"
            @test result.value.rest == "Given"
        end
    end

    @testset "GivenParser" begin
        @testset "Given some precondition; OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
            """)

            # Act
            parser = GivenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Given}
            @test result.value == Given("some precondition")
        end

        @testset "Given some other precondition; OK" begin
            # Arrange
            input = ParserInput("""
                Given some other precondition
            """)

            # Act
            parser = GivenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Given}
            @test result.value == Given("some other precondition")
        end

        @testset "When some action; Not OK" begin
            # Arrange
            input = ParserInput("""
                When some action
            """)

            # Act
            parser = GivenParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Given}
        end

        @testset "Followed by block text; OK and the text is present" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
                    \"\"\"
                    Some block text.
                    On two lines.
                    \"\"\"
            """)

            # Act
            parser = GivenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Given}
            @test result.value isa Given
            @test result.value.text == "some precondition"
            @test result.value.block_text == "Some block text.\nOn two lines."
        end

        @testset "Givennospace; Not OK" begin
            # Arrange
            input = ParserInput("""
                Givennospace some precondition
            """)

            # Act
            parser = GivenParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Given}
        end
    end

    @testset "WhenParser" begin
        @testset "When some action; OK" begin
            # Arrange
            input = ParserInput("""
                When some action
            """)

            # Act
            parser = WhenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{When}
            @test result.value == When("some action")
        end

        @testset "When some other action; OK" begin
            # Arrange
            input = ParserInput("""
                When some other action
            """)

            # Act
            parser = WhenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{When}
            @test result.value == When("some other action")
        end

        @testset "Given some precondition; Not OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
            """)

            # Act
            parser = WhenParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{When}
        end

        @testset "Followed by block text; OK and the text is present" begin
            # Arrange
            input = ParserInput("""
                When some action
                    \"\"\"
                    Some block text.
                    On two lines.
                    \"\"\"
            """)

            # Act
            parser = WhenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{When}
            @test result.value isa When
            @test result.value.text == "some action"
            @test result.value.block_text == "Some block text.\nOn two lines."
        end

        @testset "Whennospace; Not OK" begin
            # Arrange
            input = ParserInput("""
                Whennospace some action
            """)

            # Act
            parser = WhenParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{When}
        end
    end

    @testset "ThenParser" begin
        # Tests for Given and When demonstrate correct behavior
        # and the design of the parser is such that this step will
        # have the same behavior, so I'm merely demonstrating the existence
        # of a ThenParser, not fully testing it.
        @testset "Then some postcondition; OK" begin
            # Arrange
            input = ParserInput("""
                Then some postcondition
            """)

            # Act
            parser = ThenParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Then}
            @test result.value == Then("some postcondition")
        end

        @testset "Thennospace; Not OK" begin
            # Arrange
            input = ParserInput("""
                Thennospace some postcondition
            """)

            # Act
            parser = ThenParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Then}
        end
    end

    @testset "Steps parser" begin
        @testset "Two givens; OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
                Given some other precondition
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value[1] == Given("some precondition")
            @test result.value[2] == Given("some other precondition")
        end

        @testset "Two givens separated by a block text; OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
                    \"\"\"
                    Block text line 1.
                    Block text line 2.
                    \"\"\"
                Given some other precondition
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value[1] isa Given
            @test result.value[1].text == "some precondition"
            @test result.value[1].block_text == "Block text line 1.\nBlock text line 2."
            @test result.value[2] == Given("some other precondition")
        end

        @testset "Two givens follow by a block text; OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
                Given some other precondition
                    \"\"\"
                    Block text line 1.
                    Block text line 2.
                    \"\"\"
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value[1] == Given("some precondition")
            @test result.value[2] isa Given
            @test result.value[2].text == "some other precondition"
            @test result.value[2].block_text == "Block text line 1.\nBlock text line 2."
        end

        @testset "No givens; OK" begin
            # Arrange
            input = ParserInput("""
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value == []
        end

        @testset "Given then When; OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
                 When some action
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value[1] == Given("some precondition")
            @test result.value[2] == When("some action")
        end

        @testset "When, Then; OK" begin
            # Arrange
            input = ParserInput("""
                 When some action
                 Then some postcondition
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value[1] == When("some action")
            @test result.value[2] == Then("some postcondition")
        end

        @testset "Given, When, Then; OK" begin
            # Arrange
            input = ParserInput("""
                Given some precondition
                 When some action
                 Then some postcondition
            """)

            # Act
            parser = StepsParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{ScenarioStep}}
            @test result.value[1] == Given("some precondition")
            @test result.value[2] == When("some action")
            @test result.value[3] == Then("some postcondition")
        end
    end

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

    @testset "BackgroundParser" begin
        @testset "Empty Background, no description; OK" begin
            # Arrange
            input = ParserInput("""
                Background:
            """)

            # Act
            parser = BackgroundParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Background}
            @test result.value.description == ""
            @test result.value.steps == []
        end

        @testset "Empty Background, Some description; OK" begin
            # Arrange
            input = ParserInput("""
                Background: Some description
            """)

            # Act
            parser = BackgroundParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Background}
            @test result.value.description == "Some description"
            @test result.value.steps == []
        end

        @testset "Scenario:; Not OK" begin
            # Arrange
            input = ParserInput("""
                Scenario:
            """)

            # Act
            parser = BackgroundParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Background}
        end

        @testset "Given/When/Then; OK" begin
            # Arrange
            input = ParserInput("""
                Background: Some new description
                    Given some precondition
                     When some action
                     Then some precondition
            """)

            # Act
            parser = BackgroundParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Background}
            @test result.value.description == "Some new description"
            @test result.value.steps == [Given("some precondition"), When("some action"), Then("some precondition")]
        end
    end

    @testset "FeatureParser" begin
        @testset "Empty feature; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
        end

        @testset "Feature with two scenarios any steps; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario: Some scenario

                    Scenario: Some other scenario
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[2].description == "Some other scenario"
        end

        @testset "Feature with a scenario; Default background" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario: Some scenario
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            @test result.value.background.description == ""
            @test result.value.background.steps == []
        end

        @testset "Feature and Rule with one scenario; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: A feature description

                    Rule: Some rule description

                        Scenario: Some scenario
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "A feature description"
            @test result.value.scenarios[1].description == "Some rule description"
            rule = result.value.scenarios[1]
            @test rule.scenarios[1].description == "Some scenario"
        end

        @testset "Feature with a background; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Background: Some background
                        Given some precondition
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            @test result.value.background.description == "Some background"
            @test result.value.background.steps == [Given("some precondition")]
            @test result.value.scenarios == []
        end

        @testset "Feature with a background, then a Scenario; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Background: Some background
                        Given some precondition

                    Scenario: Some scenario
                        When some action
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            @test result.value.background.description == "Some background"
            @test result.value.background.steps == [Given("some precondition")]
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[1].steps == [When("some action")]
        end
    end

    @testset "FeatureFileParser" begin
        @testset "Feature with two scenarios any steps; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario: Some scenario

                    Scenario: Some other scenario
            """)

            # Act
            parser = FeatureFileParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[2].description == "Some other scenario"
        end

        @testset "Feature, then unallowed new Feature; Not OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario: Some scenario

                    Scenario: Some other scenario

                    Feature: Not allowed here
            """)

            # Act
            parser = FeatureFileParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Feature}
        end
    end

    @testset "DataTable" begin
        @testset "One row, one column; OK" begin
            # Arrange
            input = ParserInput("""
                | Foo |
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{DataTable}
            @test result.value == [["Foo"]]
        end

        @testset "One row, one column; OK" begin
            # Arrange
            input = ParserInput("""
                | Bar |
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{DataTable}
            @test result.value == [["Bar"]]
        end

        @testset "Table row then line Baz; OK" begin
            # Arrange
            input = ParserInput("""
                | Foo |
                Baz
            """)

            # Act
            parser = Sequence{Union{DataTable, String}}(DataTableParser(), Line("Baz"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{Union{DataTable, String}}}
            @test result.value[1] == [["Foo"]]
            @test result.value[2] == "Baz"
        end

        @testset "No pipes on the line; Not OK" begin
            # Arrange
            input = ParserInput("""
                Baz
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{DataTable}
        end

        @testset "Two columns; OK" begin
            # Arrange
            input = ParserInput("""
                | Foo | Bar |
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{DataTable}
            @test result.value == [["Foo", "Bar"]]
        end

        @testset "Three columns; OK" begin
            # Arrange
            input = ParserInput("""
                | Foo | Bar | Baz |
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{DataTable}
            @test result.value == [["Foo", "Bar", "Baz"]]
        end

        @testset "Two rows; OK" begin
            # Arrange
            input = ParserInput("""
                | Foo |
                | Bar |
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{DataTable}
            @test result.value == [["Foo"], ["Bar"]]
        end

        @testset "EOF; Not OK" begin
            # Arrange
            input = ParserInput("""
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{DataTable}
        end

        @testset "Many columns and rows; OK" begin
            # Arrange
            input = ParserInput("""
                | Foo | Bar |
                | Baz | Quux |
            """)

            # Act
            parser = DataTableParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{DataTable}
            @test result.value == [["Foo", "Bar"], ["Baz", "Quux"]]
        end
    end
end