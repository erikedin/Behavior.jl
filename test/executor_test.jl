using Base.Test
using BDD.Gherkin

@testset "Executor        " begin
    @testset "Execute a one-step scenario; No matching step found; Result is NoStepDefinitionFound" begin
        executor = BDD.Executor()
        scenario = Scenario("Description", [], [Given("some precondition")])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test scenarioresult.steps[1] == BDD.NoStepDefinitionFound
    end
end