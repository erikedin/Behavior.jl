using Base.Test
using BDD.Gherkin
using BDD

successful_step_definition() = BDD.SuccessfulStepExecution()
failed_step_definition() = BDD.StepFailed()
error_step_definition() = error("Some error")

struct FakeStepDefinitionMatcher <: BDD.StepDefinitionMatcher
    steps::Dict{BDD.Gherkin.ScenarioStep, Function}
end

BDD.findstepdefinition(s::FakeStepDefinitionMatcher, step::BDD.Gherkin.ScenarioStep) = s.steps[step]

@testset "Executor        " begin
    @testset "Execute a one-step scenario; No matching step found; Result is NoStepDefinitionFound" begin
        stepdefmatcher = FakeStepDefinitionMatcher(Dict{BDD.Gherkin.ScenarioStep, Function}())
        executor = BDD.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [Given("some precondition")])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], BDD.NoStepDefinitionFound)
    end

    @testset "Execute a one-step scenario; The matching step is successful; Result is Successful" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = BDD.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], BDD.SuccessfulStepExecution)
    end

    @testset "Execute a one-step scenario; The matching step fails; Result is Failed" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition))
        executor = BDD.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], BDD.StepFailed)
    end

    @testset "Execute a one-step scenario; The matching step throws an error; Result is Error" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition))
        executor = BDD.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], BDD.UnexpectedStepError)
    end

    @testset "Execute a two-step scenario; First step fails; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition,
                                                        when => successful_step_definition))
        executor = BDD.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[2], BDD.SkippedStep)
    end

    @testset "Execute a two-step scenario; Both steps success; All steps are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition))
        executor = BDD.Executor(stepdefmatcher)
        scenario = Scenario("Description", [], [given, when])

        scenarioresult = BDD.executescenario(executor, scenario)

        @test isa(scenarioresult.steps[1], BDD.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], BDD.SuccessfulStepExecution)
    end
end