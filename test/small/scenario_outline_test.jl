using BDD: parsescenario, issuccessful, Given, When, Then

@testset "Scenario Outline" begin
    @testset "Outline has a Given step; Step is parsed" begin
        text = """
        Scenario Outline: This is one scenario outline
            Given a precondition with field <Foo>

        Example:
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

        Example:
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

        Example:
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
end