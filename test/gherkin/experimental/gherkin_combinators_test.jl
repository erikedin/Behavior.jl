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

        @testset "Foo, empty line, then Baz; Empty line is included" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo

                Baz
                \"\"\"
            """)

            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo\n\nBaz"
        end

        @testset "Foo, comment, then Baz; Comment line is included" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                # Comment line
                Baz
                \"\"\"
            """)

            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo\n# Comment line\nBaz"
        end

        @testset "Foo, comment and empty, then Baz; Comment line and empty are included" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                # Comment line

                Baz
                \"\"\"
            """)

            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo\n# Comment line\n\nBaz"
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

        @testset "Feature with a scenario outline; Scenario outline is the only step" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario Outline: Some scenario
                        Given some precondition <Foo>

                        Examples:
                            | Foo |
                            | bar |
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            outline = result.value.scenarios[1]
            @test outline.description == "Some scenario"
            @test outline.placeholders == ["Foo"]
            @test outline.examples == [["bar"]]
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
            parser = DataTableParser(usenew=true)
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

    @testset "TagsParser" begin
        @testset "AnyLine; @tag; OK" begin
            # Arrange
            input = ParserInput("@tag")

            # Act
            parser = Experimental.AnyLine()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "@tag"
        end

        @testset "Splitter; @tag1 and @tag2; OK" begin
            # Arrange
            input = ParserInput("@tag1 @tag2")

            # Act
            parser = Experimental.Splitter(Experimental.AnyLine(), isspace)
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag1", "@tag2"]
        end

        @testset "Validator; All strings begin with an @; OK" begin
            # Arrange
            input = ParserInput("@tag1 @tag2")

            # Act
            inner = Experimental.Splitter(Experimental.AnyLine(), isspace)
            parser = Experimental.Validator{String}(inner, x -> startswith(x, "@"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag1", "@tag2"]
        end

        @testset "Validator; Not all strings begin with an @; Not OK" begin
            # Arrange
            input = ParserInput("@tag1 tag2")

            # Act
            inner = Experimental.Splitter(Experimental.AnyLine(), isspace)
            parser = Experimental.Validator{String}(inner, x -> startswith(x, "@"))
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Vector{String}}
        end

        @testset "@tag; OK" begin
            # Arrange
            input = ParserInput("""
                @tag
            """)

            # Act
            parser = TagParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag"]
        end

        @testset "tag; Not OK" begin
            # Arrange
            input = ParserInput("""
                tag
            """)

            # Act
            parser = TagParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Vector{String}}
        end

        @testset "EOF; Not OK" begin
            # Arrange
            input = ParserInput("")

            # Act
            parser = TagParser()
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Vector{String}}
        end

        @testset "@tag followed by Scenario:; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1
                Scenario: Some scenario
            """)

            # Act
            parser = Sequence{Union{Vector{String}, Keyword}}(
                        TagParser(),
                        KeywordParser("Scenario:")
            )
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{Union{Vector{String}, Keyword}}}
            @test result.value[1] == ["@tag1"]
            @test result.value[2] == Keyword("Scenario:", "Some scenario")
        end

        @testset "@tag1 @tag2; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
            """)

            # Act
            parser = TagParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag1", "@tag2"]
        end

        @testset "@tag1 @tag2 with multiple spaces; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1     @tag2
            """)

            # Act
            parser = TagParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag1", "@tag2"]
        end

        @testset "@tag1 then @tag2; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1
                @tag2
            """)

            # Act
            parser = TagLinesParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag1", "@tag2"]
        end

        @testset "@tag1 @tag2, then @tag3; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1 @tag2
                @tag3
            """)

            # Act
            parser = TagLinesParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["@tag1", "@tag2", "@tag3"]
        end
    end

    @testset "Tags" begin
        @testset "Empty Scenario, with tags; OK" begin
            # Arrange
            input = ParserInput("""
                @tag1
                @tag2
                Scenario: Some description
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some description"
            @test result.value.tags == ["@tag1", "@tag2"]
        end

        @testset "Empty feature with tags; OK" begin
            # Arrange
            input = ParserInput("""
                @sometag
                @othertag
                Feature: Some feature
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.tags == ["@sometag", "@othertag"]
        end

        @testset "Empty Rule with tags; OK" begin
            # Arrange
            input = ParserInput("""
                @sometag
                @othertag
                Rule: Some rule
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.tags == ["@sometag", "@othertag"]
        end
    end

    @testset "Long descriptions parser" begin
        @testset "Description Foo; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Foo
                    Given some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.long_description == "Foo"
        end

        @testset "Description Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Bar
                    Given some precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.long_description == "Bar"
        end

        @testset "Description Bar then When; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Bar
                    When some action
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.long_description == "Bar"
        end

        @testset "Description Bar then Then; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Bar
                    Then some postcondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.long_description == "Bar"
        end
    end

    @testset "Long descriptions" begin
        @testset "Description on a feature, no Background; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    This is a description.
                    On two lines.

                    Scenario: Some scenario
                        When some action
            """)

            # Act
            parser = FeatureParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Feature}
            @test result.value.header.description == "Some feature"
            @test result.value.header.long_description == ["This is a description.\nOn two lines."]
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[1].steps == [When("some action")]
        end

        @testset "Description on a feature, with Background; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    This is a description.
                    On two lines.

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
            @test result.value.header.long_description == ["This is a description.\nOn two lines."]
            @test result.value.background.description == "Some background"
            @test result.value.background.steps == [Given("some precondition")]
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[1].steps == [When("some action")]
        end

        @testset "Scenario with a description; OK" begin
            # Arrange
            input = ParserInput("""
                Scenario: Some new description
                    Foo
                    Bar
                    Baz
                    Given some precondition
                    Given some other precondition
            """)

            # Act
            parser = ScenarioParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Scenario}
            @test result.value.description == "Some new description"
            @test result.value.long_description == "Foo\nBar\nBaz"
        end

        @testset "Background with a description; OK" begin
            # Arrange
            input = ParserInput("""
                Background: Some background description

                    This is a description.
                    On two lines.

                    Given some precondition
                    Given some other precondition
            """)

            # Act
            parser = BackgroundParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Background}
            @test result.value.description == "Some background description"
            @test result.value.long_description == "This is a description.\nOn two lines."
        end

        @testset "Description on a Rule; OK" begin
            # Arrange
            input = ParserInput("""
                Rule: Some rule

                    This is a description.
                    On two lines.

                    Scenario: Some scenario
                        When some action
            """)

            # Act
            parser = RuleParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Rule}
            @test result.value.description == "Some rule"
            @test result.value.longdescription == "This is a description.\nOn two lines."
            @test result.value.scenarios[1].description == "Some scenario"
            @test result.value.scenarios[1].steps == [When("some action")]
        end

        # TODO Scenario Outline
    end
end