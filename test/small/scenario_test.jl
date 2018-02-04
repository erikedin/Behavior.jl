using BDD: parsescenario, issuccessful

@testset "Scenario" begin
    @testset "Parse scenario; Read description; Description matches scenario" begin
        text = """
        Scenario: This is a description
            Given a precondition
        """

        result = parsescenario(text)

        @test issuccessful(result)
        @test result.value.description == "This is a description"
    end

    @testset "Parse scenario; Read another description; Description matches scenario" begin
        text = """
        Scenario: This is another description
            Given a precondition
        """

        result = parsescenario(text)

        @test issuccessful(result)
        @test result.value.description == "This is another description"
    end
end