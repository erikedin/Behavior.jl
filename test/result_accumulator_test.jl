using ExecutableSpecifications.Gherkin
using ExecutableSpecifications:
    ResultAccumulator, accumulateresult!, issuccess, featureresults,
    FeatureResult, ScenarioResult, Given, SuccessfulStepExecution, Scenario, StepFailed

@testset "Result Accumulator   " begin
    @testset "Accumulate results; One feature with a successful scenario; Total result is success" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [successfulscenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator)
    end

    @testset "Accumulate results; One feature with a failing scenario; Total result is fail" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        scenario = ScenarioResult(
            [StepFailed("")],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [scenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; One scenario with one successful and one failing step; Total result is fail" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        when = When("some action")
        scenario = ScenarioResult(
            [SuccessfulStepExecution(), StepFailed("")],
            Scenario("Some scenario", String[], ScenarioStep[given, when]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [scenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; Two scenarios, one failing; Total result is fail" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        failingscenario = ScenarioResult(
            [StepFailed("")],
            Scenario("Some other scenario", String[],  ScenarioStep[when]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [successfulscenario, failingscenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end

    @testset "Accumulate results; One feature, one passing Scenario; One success and zero failures" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [successfulscenario])

        accumulateresult!(accumulator, featureresult)

        @test featureresults(accumulator)[1].n_success == 1
        @test featureresults(accumulator)[1].n_failure == 0
    end

    @testset "Accumulate results; Two scenarios, one failing; One success and one failure" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        failingscenario = ScenarioResult(
            [StepFailed("")],
            Scenario("Some other scenario", String[],  ScenarioStep[when]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [successfulscenario, failingscenario])

        accumulateresult!(accumulator, featureresult)

        @test featureresults(accumulator)[1].n_success == 1
        @test featureresults(accumulator)[1].n_failure == 1
    end

    @testset "Accumulate results; Seven scenarios, two failing; 5 success and 2 failures" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        when = When("some action")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        failingscenario = ScenarioResult(
            [StepFailed("")],
            Scenario("Some other scenario", String[],  ScenarioStep[when]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature,
            [successfulscenario, successfulscenario, successfulscenario, successfulscenario, successfulscenario,
             failingscenario, failingscenario])

        accumulateresult!(accumulator, featureresult)

        @test featureresults(accumulator)[1].n_success == 5
        @test featureresults(accumulator)[1].n_failure == 2
    end

    @testset "Accumulate results; Two successful features; Both have no failures" begin
        accumulator = ResultAccumulator()

        feature1 = Gherkin.Feature(FeatureHeader("1", [], []), Scenario[])
        feature2 = Gherkin.Feature(FeatureHeader("1", [], []), Scenario[])
        given = Given("some precondition")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        featureresult1 = FeatureResult(feature1, [successfulscenario])
        featureresult2 = FeatureResult(feature1, [successfulscenario])

        accumulateresult!(accumulator, featureresult1)
        accumulateresult!(accumulator, featureresult2)

        @test featureresults(accumulator)[1].n_success > 0
        @test featureresults(accumulator)[1].n_failure == 0
        @test featureresults(accumulator)[2].n_success > 0
        @test featureresults(accumulator)[2].n_failure == 0
    end

    @testset "Accumulate results; Failing Background with a successful Scenario; Total result is failed" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background("Failing background", ScenarioStep[Given("some failing background step")]),
            StepExecutionResult[
                StepFailed(""),
            ])
        featureresult = FeatureResult(feature, [successfulscenario])

        accumulateresult!(accumulator, featureresult)

        @test issuccess(accumulator) == false
    end


    @testset "Accumulate results; One feature with a successful scenario; Results accumulator is not empty" begin
        accumulator = ResultAccumulator()

        feature = Gherkin.Feature(FeatureHeader("", [], []), Scenario[])
        given = Given("some precondition")
        successfulscenario = ScenarioResult(
            [SuccessfulStepExecution()],
            Scenario("Some scenario", String[], ScenarioStep[given]),
            Background(),
            ScenarioStep[])
        featureresult = FeatureResult(feature, [successfulscenario])

        accumulateresult!(accumulator, featureresult)

        @test !isempty(accumulator)
    end

    @testset "Accumulate results; No features; Results accumulator is empty" begin
        accumulator = ResultAccumulator()

        @test isempty(accumulator)
    end

    @testset "Accumulate results; One feature with syntax error; Total result is failure" begin
        accumulator = ResultAccumulator()

        parseresult = Gherkin.BadParseResult{Feature}(:somereason, :someexpected, :someactual, 0, "Some line")

        accumulateresult!(accumulator, parseresult, "features/some/path/to/my.feature")

        @test issuccess(accumulator) == false
    end
end