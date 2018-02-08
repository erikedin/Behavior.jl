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

    @testset "Scenario has a When step; the parsed scenario has a When struct" begin
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

    @testset "Scenario has a Then step; the parsed scenario has a Then struct" begin
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

    @testset "Scenario has an And following a Given; the And step becomes a Given" begin
        text = """
        Scenario: Some description
            Given a precondition
              And another precondition
        """

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == BDD.ScenarioStep[Given("a precondition"),
                                                 Given("another precondition")]
    end

    @testset "Scenario has an And following a When; the And step becomes a When" begin
        text = """
        Scenario: Some description
            When some action
             And another action
        """

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == BDD.ScenarioStep[When("some action"),
                                                 When("another action")]
    end

    @testset "Scenario has an And following a Then; the And step becomes a Then" begin
        text = """
        Scenario: Some description
            Then some postcondition
             And another postcondition
        """

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == BDD.ScenarioStep[Then("some postcondition"),
                                                 Then("another postcondition")]
    end

    @testset "Scenario is not terminated by newline; EOF is also an OK termination" begin
        text = """
        Scenario: Some description
            Then some postcondition
            And another postcondition"""

        byline = BDD.ByLineParser(text)
        result = parsescenario(byline)

        @test issuccessful(result)
    end
end