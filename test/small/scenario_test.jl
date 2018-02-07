using BDD: issuccessful, parsescenario, Given

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
end