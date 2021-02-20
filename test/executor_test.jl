using Test
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications.Gherkin: ScenarioStep, Background
using ExecutableSpecifications
using ExecutableSpecifications: StepDefinitionContext, StepDefinition, StepDefinitionLocation
using ExecutableSpecifications: Executor, StepExecutionResult, QuietRealTimePresenter, executefeature
import ExecutableSpecifications: present

successful_step_definition(::StepDefinitionContext) = ExecutableSpecifications.SuccessfulStepExecution()
failed_step_definition(::StepDefinitionContext) = ExecutableSpecifications.StepFailed("")
error_step_definition(::StepDefinitionContext) = error("Some error")

struct FakeStepDefinitionMatcher <: ExecutableSpecifications.StepDefinitionMatcher
    steps::Dict{ExecutableSpecifications.Gherkin.ScenarioStep, Function}
end

ExecutableSpecifications.findstepdefinition(s::FakeStepDefinitionMatcher, step::ExecutableSpecifications.Gherkin.ScenarioStep) = StepDefinition("some text", s.steps[step], StepDefinitionLocation("", 0))

struct ThrowingStepDefinitionMatcher <: ExecutableSpecifications.StepDefinitionMatcher
    ex::Exception
end

ExecutableSpecifications.findstepdefinition(matcher::ThrowingStepDefinitionMatcher, ::ExecutableSpecifications.Gherkin.ScenarioStep) = throw(matcher.ex)

@testset "Executor             " begin
    @testset "Execute a one-step scenario; No matching step found; Result is NoStepDefinitionFound" begin
        stepdefmatcher = ThrowingStepDefinitionMatcher(ExecutableSpecifications.NoMatchingStepDefinition())
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[Given("some precondition")])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.NoStepDefinitionFound)
    end

    @testset "Execute a one-step scenario; The matching step is successful; Result is Successful" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a one-step scenario; The matching step fails; Result is Failed" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.StepFailed)
    end

    @testset "Execute a one-step scenario; The matching step throws an error; Result is Error" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.UnexpectedStepError)
    end

    @testset "Execute a two-step scenario; First step throws an error; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SkippedStep)
    end

    @testset "Execute a two-step scenario; First step fails; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SkippedStep)
    end

    @testset "Execute a two-step scenario; Both steps succeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

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
        scenario = Scenario("Description", String[], ScenarioStep[given, when, then])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], ExecutableSpecifications.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[3], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Execute a scenario; Scenario is provided; Scenario is returned with the result" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("This is a scenario", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test scenarioresult.scenario == scenario
    end

    @testset "Execute a scenario; No unique step definition found; Result is NonUniqueMatch" begin
        stepdefmatcher = ThrowingStepDefinitionMatcher(ExecutableSpecifications.NonUniqueStepDefinition([]))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[Given("some precondition")])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.NonUniqueMatch)
    end

    @testset "Execute a ScenarioOutline; Outline has two examples; Two scenarios are returned" begin
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], ["1" "2"])
        step1 = Given("step 1")
        step2 = Given("step 2")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                        step2 => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        outlineresult = ExecutableSpecifications.executescenario(executor, Background(), outline)

        @test length(outlineresult) == 2
    end

    @testset "Execute a ScenarioOutline; Outline has a successful and a failing example; First is success, second is fail" begin
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], ["1" "2"])
        step1 = Given("step 1")
        step2 = Given("step 2")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                        step2 => failed_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        outlineresult = ExecutableSpecifications.executescenario(executor, Background(), outline)

        @test outlineresult[1].steps[1] isa ExecutableSpecifications.SuccessfulStepExecution
        @test outlineresult[2].steps[1] isa ExecutableSpecifications.StepFailed
    end

    @testset "Execute a ScenarioOutline; Outline has three examples; Three scenarios are returned" begin
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], ["1" "2" "3"])
        step1 = Given("step 1")
        step2 = Given("step 2")
        step3 = Given("step 3")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                        step2 => successful_step_definition,
                                                        step3 => successful_step_definition))
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        outlineresult = ExecutableSpecifications.executescenario(executor, Background(), outline)

        @test length(outlineresult) == 3
    end

    @testset "Block text" begin
        @testset "Scenario step has a block text; Context contains the block text" begin
            given = Given("Some precondition", block_text="Some block text")
            function check_block_text_step_definition(context::StepDefinitionContext)
                if context[:block_text] == "Some block text"
                    ExecutableSpecifications.SuccessfulStepExecution()
                else
                    ExecutableSpecifications.StepFailed("")
                end
            end
            stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => check_block_text_step_definition))
            executor = ExecutableSpecifications.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[given])

            scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

            @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
        end

        @testset "First step has block text, but second doesn't; The block text is cleared in the second step" begin
            given = Given("Some precondition", block_text="Some block text")
            when = When("some action")
            function check_block_text_step_definition(context::StepDefinitionContext)
                if context[:block_text] == ""
                    ExecutableSpecifications.SuccessfulStepExecution()
                else
                    ExecutableSpecifications.StepFailed("")
                end
            end
            stepdefmatcher = FakeStepDefinitionMatcher(Dict(
                given => successful_step_definition,
                when => check_block_text_step_definition))
            executor = ExecutableSpecifications.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], [given, when])

            scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

            @test isa(scenarioresult.steps[2], ExecutableSpecifications.SuccessfulStepExecution)
        end
    end
end
