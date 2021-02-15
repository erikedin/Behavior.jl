using ExecutableSpecifications.Gherkin: parsescenario!, issuccessful, Given, When, Then, ByLineParser, ScenarioStep

@testset "Scenario Outline     " begin
    @testset "Outline has a Given step; Step is parsed" begin
        text = """
        Scenario Outline: This is one scenario outline
            Given a precondition with field <Foo>

        Examples:
            | Foo |
            | 1   |
            | 2   |
        """
        byline = ByLineParser(text)

        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value
        @test scenario.steps == ScenarioStep[Given("a precondition with field <Foo>")]
    end

    @testset "Scenario Outline has description; Description is parsed" begin
        text = """
        Scenario Outline: This is one scenario outline
            Given a precondition with field <Foo>

        Examples:
            | Foo |
            | 1   |
            | 2   |
        """
        byline = ByLineParser(text)

        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value
        @test scenario.description == "This is one scenario outline"
    end

    @testset "Scenario Outline has tags; Tags are parsed" begin
        text = """
        @tag1 @tag2
        Scenario Outline: This is one scenario outline
            Given a precondition with field <Foo>

        Examples:
            | Foo |
            | 1   |
            | 2   |
        """
        byline = ByLineParser(text)

        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value
        @test scenario.tags == ["@tag1", "@tag2"]
    end

    @testset "Scenario Outline Examples" begin
        @testset "Outline has three placeholders; The placeholders are parsed" begin
            text = """
            Scenario Outline: This is one scenario outline
                Given a precondition with placeholders <Foo>, <Bar>, <Baz>

            Examples:
                | Foo | Bar | Baz |
                | 1   | 2   | 3   |
                | 1   | 2   | 3   |
            """
            byline = ByLineParser(text)

            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value
            @test scenario.placeholders == ["Foo", "Bar", "Baz"]
        end

        @testset "Two examples with three placeholders are provided; Examples array is 3x2" begin
            text = """
            Scenario Outline: This is one scenario outline
                Given a precondition with placeholders <Foo>, <Bar>, <Baz>

            Examples:
                | Foo | Bar | Baz |
                | 1   | 2   | 3   |
                | 1   | 2   | 3   |
            """
            byline = ByLineParser(text)

            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value
            @test size(scenario.examples) == (3,2)
        end

        @testset "Three examples with four placeholders are provided; Examples array is 4x3" begin
            text = """
            Scenario Outline: This is one scenario outline
                Given a precondition with placeholders <Foo>, <Bar>, <Baz>, <Quux>

            Examples:
                | Foo | Bar | Baz | Quux |
                | 1   | 2   | 3   | 4    |
                | 1   | 2   | 3   | 4    |
                | 1   | 2   | 3   | 4    |
            """
            byline = ByLineParser(text)

            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value
            @test size(scenario.examples) == (4,3)
        end

        @testset "Two examples with three placeholders are provided; Examples array has all values" begin
            text = """
            Scenario Outline: This is one scenario outline
                Given a precondition with placeholders <Foo>, <Bar>, <Baz>

            Examples:
                | Foo | Bar | Baz |
                | 1   | 2   | 3   |
                | 4   | 5   | 6   |
            """
            byline = ByLineParser(text)

            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value
            @test scenario.examples[:,1] == ["1", "2", "3"]
            @test scenario.examples[:,2] == ["4", "5", "6"]
        end

        @testset "Examples with spaces; Examples are split on | not on spaces" begin
            text = """
            Scenario Outline: This is one scenario outline
                Given a precondition with placeholder <Foo>

            Examples:
                | Foo       |
                | word      |
                | two words |
            """
            byline = ByLineParser(text)

            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value
            @test scenario.examples[:,1] == ["word"]
            @test scenario.examples[:,2] == ["two words"]
        end

        @testset "Example with an empty element; The empty line results in an empty value" begin
            text = """
            Scenario Outline: This is one scenario outline
                Given a precondition with placeholder <Foo>

            Examples:
                | Foo       |
                ||
                | two words |
            """
            byline = ByLineParser(text)

            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value
            @test scenario.examples[:,1] == [""]
            @test scenario.examples[:,2] == ["two words"]
        end
    end
end