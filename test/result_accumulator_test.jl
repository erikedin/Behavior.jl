using ExecutableSpecifications:
    ResultAccumulator, accumulateresult, issuccess,
    FeatureResult, ScenarioResult, Given, SuccessfulStepExecution, Scenario, StepFailed

@testset "Result Accumulator" begin
    @testset "Accumulate results; One feature with a successful scenario; Total result is success" begin
        accumulator = ResultAccumulator()

        given = Given("some precondition")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        featureresult = FeatureResult([successfulscenario])

        accumulateresult(accumulator, featureresult)

        @test issuccess(accumulator)
    end

    @testset "Accumulate results; One feature with a failing scenario; Total result is fail" begin
        accumulator = ResultAccumulator()

        given = Given("some precondition")
        scenario = ScenarioResult([StepFailed()], Scenario("Some scenario", [], [given]))
        featureresult = FeatureResult([scenario])

        accumulateresult(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; One scenario with one successful and one failing step; Total result is fail" begin
        accumulator = ResultAccumulator()

        given = Given("some precondition")
        when = When("some action")
        scenario = ScenarioResult([SuccessfulStepExecution(), StepFailed()], Scenario("Some scenario", [], [given, when]))
        featureresult = FeatureResult([scenario])

        accumulateresult(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; Two scenarios, one failing; Total result is fail" begin
        accumulator = ResultAccumulator()

        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        failingscenario = ScenarioResult([StepFailed()], Scenario("Some other scenario", [],  [when]))
        featureresult = FeatureResult([successfulscenario, failingscenario])

        accumulateresult(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end
end