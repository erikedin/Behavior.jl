using Test
using Behavior.Gherkin
using Behavior.Gherkin: ScenarioStep, Background
using Behavior
using Behavior: StepDefinitionContext, StepDefinition, StepDefinitionLocation
using Behavior: Executor, StepExecutionResult, QuietRealTimePresenter, executefeature, ScenarioResult
import Behavior: present

mutable struct FakeRealTimePresenter <: Behavior.RealTimePresenter
    scenarios::Vector{Scenario}
    scenarioresults::Vector{ScenarioResult}
    steps::Vector{ScenarioStep}
    results::Dict{ScenarioStep, StepExecutionResult}
    features::Vector{Feature}

    FakeRealTimePresenter() = new([], [], [], Dict(), [])
end

present(p::FakeRealTimePresenter, scenario::Scenario) = push!(p.scenarios, scenario)
present(p::FakeRealTimePresenter, _scenario::Scenario, result::ScenarioResult) = push!(p.scenarioresults, result)
present(p::FakeRealTimePresenter, step::ScenarioStep) = push!(p.steps, step)
present(p::FakeRealTimePresenter, step::ScenarioStep, result::StepExecutionResult) = p.results[step] = result
present(p::FakeRealTimePresenter, feature::Feature) = push!(p.features, feature)

stepresult(p::FakeRealTimePresenter, step::ScenarioStep) = p.results[step]

@testset "Executor Presentation" begin
    @testset "Execution presentation; Scenario is executed; Scenario is presented" begin
        presenter = FakeRealTimePresenter()
        matcher = FakeStepDefinitionMatcher(Dict())
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[])
        Behavior.executescenario(executor,  Background(),scenario)

        @test presenter.scenarios[1] == scenario
    end

    @testset "Execution presentation; Scenario is executed; ScenarioResult is presented" begin
        presenter = FakeRealTimePresenter()
        matcher = FakeStepDefinitionMatcher(Dict())
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[])
        Behavior.executescenario(executor,  Background(),scenario)

        @test presenter.scenarioresults[1].scenario == scenario
    end

    @testset "Execution presentation; Scenario has on Given; Given is presented" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[given])
        Behavior.executescenario(executor,  Background(),scenario)

        @test presenter.steps[1] == given
    end

    @testset "Execution presentation; Scenario step is successful; Step is presented as successful" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        matcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[given])
        Behavior.executescenario(executor,  Background(),scenario)

        @test stepresult(presenter, given) == Behavior.SuccessfulStepExecution()
    end

    @testset "Execution presentation; Scenario step fails; Next is also presented" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        when = When("some action")
        matcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                 when => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[given, when])
        Behavior.executescenario(executor,  Background(),scenario)

        @test presenter.steps[2] == when
    end

    @testset "Execution presentation; Scenario step fails; Next has result Skipped" begin
        presenter = FakeRealTimePresenter()
        given = Given("some precondition")
        when = When("some action")
        matcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                 when => successful_step_definition))
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[given, when])
        Behavior.executescenario(executor,  Background(),scenario)

        @test stepresult(presenter, when) == Behavior.SkippedStep()
    end

    @testset "Execution presentation; Feature is executed; Feature is presented" begin
        presenter = FakeRealTimePresenter()
        matcher = FakeStepDefinitionMatcher(Dict())
        executor = Executor(matcher, presenter)

        scenario = Scenario("Some scenario", String[], ScenarioStep[])
        feature = Feature(FeatureHeader("", [], []), [scenario])
        Behavior.executefeature(executor, feature)

        @test presenter.features[1] == feature
    end
end