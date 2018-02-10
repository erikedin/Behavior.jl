using BDD: issuccessful, parsescenario, Given, When, Then

@testset "Scenario        " begin
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

    @testset "Malformed scenarios" begin
        @testset "And as a first step; Expected Given, When, or Then before that" begin
            text = """
            Scenario: Some description
                And another postcondition
            """

            byline = BDD.ByLineParser(text)
            result = parsescenario(byline)

            @test !issuccessful(result)
            @test result.reason == :leading_and
            @test result.expected == :specific_step
            @test result.actual == :and_step
        end

        @testset "Given after a When; Expected When or Then" begin
            text = """
            Scenario: Some description
                 When some action
                Given some precondition
            """

            byline = BDD.ByLineParser(text)
            result = parsescenario(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotGiven
            @test result.actual == :Given
        end

        @testset "Given after Then; Expected Then" begin
            text = """
            Scenario: Some description
                Then some postcondition
                Given some precondition
            """

            byline = BDD.ByLineParser(text)
            result = parsescenario(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotGiven
            @test result.actual == :Given
        end

        @testset "When after Then; Expected Then" begin
            text = """
            Scenario: Some description
                Then some postcondition
                When some action
            """

            byline = BDD.ByLineParser(text)
            result = parsescenario(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotWhen
            @test result.actual == :When
        end

        @testset "Invalid step definition NotAStep; Expected a valid step definition" begin
            text = """
            Scenario: Some description
                NotAStep some more text
            """

            byline = BDD.ByLineParser(text)
            result = parsescenario(byline)

            @test !issuccessful(result)
            @test result.reason == :invalid_step
            @test result.expected == :step_definition
            @test result.actual == :invalid_step_definition
        end

        @testset "A step definition without text; Expected a valid step definition" begin
            text = """
            Scenario: Some description
                Given
            """

            byline = BDD.ByLineParser(text)
            result = parsescenario(byline)

            @test !issuccessful(result)
            @test result.reason == :invalid_step
            @test result.expected == :step_definition
            @test result.actual == :invalid_step_definition
        end
    end
end