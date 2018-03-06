using Base.Test
using BDD.Gherkin
using BDD

successful_step_definition() = BDD.SuccessfulStepExecution()
failed_step_definition() = BDD.StepFailed()

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
end