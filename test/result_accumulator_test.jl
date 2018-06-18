using ExecutableSpecifications.Gherkin
using ExecutableSpecifications:
    ResultAccumulator, accumulateresult!, issuccess, featureresults,
    FeatureResult, ScenarioResult, Given, SuccessfulStepExecution, Scenario, StepFailed

@testset "Result Accumulator" begin
    @testset "Accumulate results; One feature with a successful scenario; Total result is success" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        featureresult = FeatureResult(feature, [successfulscenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator)
    end

    @testset "Accumulate results; One feature with a failing scenario; Total result is fail" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        scenario = ScenarioResult([StepFailed("")], Scenario("Some scenario", [], [given]))
        featureresult = FeatureResult(feature, [scenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; One scenario with one successful and one failing step; Total result is fail" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        when = When("some action")
        scenario = ScenarioResult([SuccessfulStepExecution(), StepFailed("")], Scenario("Some scenario", [], [given, when]))
        featureresult = FeatureResult(feature, [scenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; Two scenarios, one failing; Total result is fail" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        failingscenario = ScenarioResult([StepFailed("")], Scenario("Some other scenario", [],  [when]))
        featureresult = FeatureResult(feature, [successfulscenario, failingscenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; One feature, one passing Scenario; One success and zero failures" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        featureresult = FeatureResult(feature, [successfulscenario])

        accumulateresult!(accumulator, featureresult)

        @test featureresults(accumulator)[1].n_success == 1
        @test featureresults(accumulator)[1].n_failure == 0
    end

    @testset "Accumulate results; Two scenarios, one failing; One success and one failure" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        failingscenario = ScenarioResult([StepFailed("")], Scenario("Some other scenario", [],  [when]))
        featureresult = FeatureResult(feature, [successfulscenario, failingscenario])

        accumulateresult!(accumulator, featureresult)

        @test featureresults(accumulator)[1].n_success == 1
        @test featureresults(accumulator)[1].n_failure == 1
    end

    @testset "Accumulate results; Seven scenarios, two failing; 5 success and 2 failures" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), [])
        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        failingscenario = ScenarioResult([StepFailed("")], Scenario("Some other scenario", [],  [when]))
        featureresult = FeatureResult(feature,
            [successfulscenario, successfulscenario, successfulscenario, successfulscenario, successfulscenario,
             failingscenario, failingscenario])

        accumulateresult!(accumulator, featureresult)

        @test featureresults(accumulator)[1].n_success == 5
        @test featureresults(accumulator)[1].n_failure == 2
    end

    @testset "Accumulate results; Two successful features; Both have no failures" begin
        accumulator = ResultAccumulator()

        feature1 = Gherkin.Feature(FeatureHeader("1", [], []), [])
        feature2 = Gherkin.Feature(FeatureHeader("1", [], []), [])
        given = Given("some precondition")
        successfulscenario = ScenarioResult([SuccessfulStepExecution()], Scenario("Some scenario", [], [given]))
        featureresult1 = FeatureResult(feature1, [successfulscenario])
        featureresult2 = FeatureResult(feature1, [successfulscenario])

        accumulateresult!(accumulator, featureresult1)
        accumulateresult!(accumulator, featureresult2)

        @test featureresults(accumulator)[1].n_success > 0
        @test featureresults(accumulator)[1].n_failure == 0
        @test featureresults(accumulator)[2].n_success > 0
        @test featureresults(accumulator)[2].n_failure == 0
    end
end