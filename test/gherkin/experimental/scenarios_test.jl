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
end