using BDD: parsescenario, issuccessful

@testset "Scenario" begin
    @testset "Scenario description" begin
        text = """
        Scenario: This is a description
            Given a precondition
        """

        result = parsescenario(text)

        @test issuccessful(result)
        @test result.value.description == "This is a description"
    end
end