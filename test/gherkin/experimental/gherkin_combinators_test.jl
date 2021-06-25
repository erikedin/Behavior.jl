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
            @test result isa OKParseResult{Vector{Given}}
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
            @test result isa OKParseResult{Vector{Given}}
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
            @test result isa OKParseResult{Vector{Given}}
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
            @test result isa OKParseResult{Vector{Given}}
            @test result.value == []
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
    end
end