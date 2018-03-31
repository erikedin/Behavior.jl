using ExecutableSpecifications:
    ResultAccumulator, accumulateresult, issuccess,
    FeatureResult, ScenarioResult, Given, SuccessfulStepExecution, Scenario

@testset "Result Accumulator" begin
    @testset "Accumulate results; One feature with a successful scenario; Total result is success" begin
        accumulator = ResultAccumulator()

        given = Given("some precondition")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        featureresult = FeatureResult([successfulscenario])

        accumulateresult(accumulator, featureresult)

        @test issuccess(accumulator)
    end
end