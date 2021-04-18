using Test
using Behavior.Gherkin
using Behavior.Gherkin: ScenarioStep
using Behavior
using Behavior: StepDefinitionContext, StepDefinition, StepDefinitionLocation
using Behavior: Executor, StepExecutionResult, QuietRealTimePresenter, executefeature
import ExecutableSpecifications: present

@testset "Feature Executor     " begin
    @testset "Execute a feature; Feature has one scenario; Feature result has one scenario result" begin
        presenter = QuietRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        scenario = Scenario("some scenario", String[], ScenarioStep[given])
        featureheader = FeatureHeader("Some feature", [], [])
        feature = Feature(featureheader, [scenario])
        executor = Executor(matcher, presenter)

        featureresult = executefeature(executor, feature)

        @test length(featureresult.scenarioresults) == 1
    end

    @testset "Execute a feature; Feature has two scenarios; Result has two scenario results" begin
        presenter = QuietRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        scenario1 = Scenario("some scenario", String[], ScenarioStep[given])
        scenario2 = Scenario("some other scenario", String[], ScenarioStep[given])
        featureheader = FeatureHeader("Some feature", [], [])
        feature = Feature(featureheader, [scenario1, scenario2])
        executor = Executor(matcher, presenter)

        featureresult = executefeature(executor, feature)

        @test length(featureresult.scenarioresults) == 2
    end

    @testset "Execute a feature; Feature has three scenarios; Scenarios are executed in order" begin
        presenter = QuietRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        scenario1 = Scenario("some scenario", String[], ScenarioStep[given])
        scenario2 = Scenario("some other scenario", String[], ScenarioStep[given])
        scenario3 = Scenario("some third scenario", String[], ScenarioStep[given])
        featureheader = FeatureHeader("Some feature", [], [])
        feature = Feature(featureheader, [scenario1, scenario2, scenario3])
        executor = Executor(matcher, presenter)

        featureresult = executefeature(executor, feature)

        @test featureresult.scenarioresults[1].scenario == scenario1
        @test featureresult.scenarioresults[2].scenario == scenario2
        @test featureresult.scenarioresults[3].scenario == scenario3
    end

    @testset "Execute a feature; Feature has one failing scenario; Scenario result has a failing step" begin
        presenter = QuietRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition))
        scenario = Scenario("some scenario", String[], ScenarioStep[given])
        featureheader = FeatureHeader("Some feature", [], [])
        feature = Feature(featureheader, [scenario])
        executor = Executor(matcher, presenter)

        featureresult = executefeature(executor, feature)

        @test featureresult.scenarioresults[1].steps[1] isa ExecutableSpecifications.StepFailed
    end

    @testset "Execute a feature; One Scenario and an Outline with two examples; Three results" begin
        presenter = QuietRealTimePresenter()

        step1 = Given("step 1")
        step2 = Given("step 2")
        scenario = Scenario("some scenario", String[], ScenarioStep[step1])
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], ["1" "2"])
        matcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                 step2 => successful_step_definition))

        featureheader = FeatureHeader("Some feature", [], [])
        feature = Feature(featureheader, [scenario, outline])
        executor = Executor(matcher, presenter)

        featureresult = executefeature(executor, feature)

        @test length(featureresult.scenarioresults) == 3
    end
end