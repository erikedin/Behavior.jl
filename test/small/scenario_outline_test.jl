using BDD: parsescenario, issuccessful, Given, When, Then

@testset "Scenario Outline" begin
    @testset "Outline has a Given step; Step is parsed" begin
        text = """
        Scenario Outline: This is one scenario outline
            Given a precondition with field <Foo>

        Examples:
            | Foo |
            | 1   |
            | 2   |
        """
        byline = BDD.ByLineParser(text)

        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value
        @test scenario.steps == BDD.ScenarioStep[Given("a precondition with field <Foo>")]
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
        byline = BDD.ByLineParser(text)

        result = parsescenario(byline)

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
        byline = BDD.ByLineParser(text)

        result = parsescenario(byline)

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
            byline = BDD.ByLineParser(text)

            result = parsescenario(byline)

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
            byline = BDD.ByLineParser(text)

            result = parsescenario(byline)

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
            byline = BDD.ByLineParser(text)

            result = parsescenario(byline)

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
            byline = BDD.ByLineParser(text)

            result = parsescenario(byline)

            @test issuccessful(result)
            scenario = result.value
            @test scenario.examples[:,1] == ["1", "2", "3"]
            @test scenario.examples[:,2] == ["4", "5", "6"]
        end
    end

    @testset "Malformed Scenario Outlines" begin
        @testset "Invalid step definition; Parse is unsuccessful" begin
            text = """
            Scenario Outline: This is one scenario outline
                NotAStepDefinition with placeholders <Foo>, <Bar>, <Baz>

            Examples:
                | Foo | Bar | Baz |
                | 1   | 2   | 3   |
                | 4   | 5   | 6   |
            """
            byline = BDD.ByLineParser(text)

            result = parsescenario(byline)

            @test !issuccessful(result)
        end
    end
end