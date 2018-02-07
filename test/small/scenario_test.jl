using BDD: issuccessful, parsescenario, Given, When, Then

@testset "Scenario" begin
    @testset "Scenario has a Given step; the parsed scenario has a Given struct" begin
        text = """
        Scenario: Some description
            Given a precondition
        """

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == BDD.ScenarioStep[Given("a precondition")]
    end

    @testset "Scenario has a Given step; the parsed scenario has a Given struct" begin
        text = """
        Scenario: Some description
            When some action
        """

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == BDD.ScenarioStep[When("some action")]
    end

    @testset "Scenario has a Given step; the parsed scenario has a Given struct" begin
        text = """
        Scenario: Some description
            Then a postcondition
        """

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == BDD.ScenarioStep[Then("a postcondition")]
    end
end