using Base.Test
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications
using ExecutableSpecifications: StepDefinitionContext

successful_step_definition(::StepDefinitionContext) = ExecutableSpecifications.SuccessfulStepExecution()
failed_step_definition(::StepDefinitionContext) = ExecutableSpecifications.StepFailed()
error_step_definition(::StepDefinitionContext) = error("Some error")

struct FakeStepDefinitionMatcher <: ExecutableSpecifications.StepDefinitionMatcher
    steps::Dict{ExecutableSpecifications.Gherkin.ScenarioStep, Function}
end

ExecutableSpecifications.findstepdefinition(s::FakeStepDefinitionMatcher, step::ExecutableSpecifications.Gherkin.ScenarioStep) = s.steps[step]

@testset "Executor        " begin
    @testset "Execute a one-step scenario; No matching step found; Result is NoStepDefinitionFound" begin
        stepdefmatcher = FakeStepDefinitionMatcher(Dict{ExecutableSpecifications.Gherkin.ScenarioStep, Function}())
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [Given("some precondition")])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.NoStepDefinitionFound)
    end

    @testset "Execute a one-step scenario; The matching step is successful; Result is Successful" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a one-step scenario; The matching step fails; Result is Failed" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.StepFailed)
    end

    @testset "Execute a one-step scenario; The matching step throws an error; Result is Error" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.UnexpectedStepError)
    end

    @testset "Execute a two-step scenario; First step throws an error; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SkippedStep)
    end

    @testset "Execute a two-step scenario; First step fails; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SkippedStep)
    end

    @testset "Execute a two-step scenario; Both steps succeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a three-step scenario; All steps succeeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        then = Then("some postcondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition,
                                                        then => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when, then])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[3], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a scenario; Scenario is provided; Scenario is returned with the result" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("This is a scenario", [], [given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, scenario)

        @test scenarioresult.scenario == scenario
    end
end