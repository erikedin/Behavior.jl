# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

using Test
using Behavior.Gherkin
using Behavior.Gherkin: ScenarioStep, Background
using Behavior
using Behavior: StepDefinitionContext, StepDefinition, StepDefinitionLocation, StepDefinitionMatch
using Behavior: Executor, StepExecutionResult, QuietRealTimePresenter, executefeature
import Behavior: present

successful_step_definition(::StepDefinitionContext, args) = Behavior.SuccessfulStepExecution()
failed_step_definition(::StepDefinitionContext, args) = Behavior.StepFailed("")
error_step_definition(::StepDefinitionContext, args) = error("Some error")

struct FakeStepDefinitionMatcher <: Behavior.StepDefinitionMatcher
    steps::Dict{Behavior.Gherkin.ScenarioStep, Function}
end

function Behavior.findstepdefinition(s::FakeStepDefinitionMatcher, step::Behavior.Gherkin.ScenarioStep)
    if step in keys(s.steps)
        StepDefinitionMatch(StepDefinition("some text", s.steps[step], StepDefinitionLocation("", 0)))
    else
        throw(Behavior.NoMatchingStepDefinition())
    end
end

struct ThrowingStepDefinitionMatcher <: Behavior.StepDefinitionMatcher
    ex::Exception
end

Behavior.findstepdefinition(matcher::ThrowingStepDefinitionMatcher, ::Behavior.Gherkin.ScenarioStep) = throw(matcher.ex)

@testset "Executor             " begin
    @testset "Execute a one-step scenario; No matching step found; Result is NoStepDefinitionFound" begin
        stepdefmatcher = ThrowingStepDefinitionMatcher(Behavior.NoMatchingStepDefinition())
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[Given("some precondition")])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.NoStepDefinitionFound)
    end

    @testset "Execute a one-step scenario; The matching step is successful; Result is Successful" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
    end

    @testset "Execute a one-step scenario; The matching step fails; Result is Failed" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.StepFailed)
    end

    @testset "Execute a one-step scenario; The matching step throws an error; Result is Error" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.UnexpectedStepError)
    end

    @testset "Execute a two-step scenario; First step throws an error; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => error_step_definition,
                                                        when => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[2], Behavior.SkippedStep)
    end

    @testset "Execute a two-step scenario; First step fails; Second step is Skipped" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => failed_step_definition,
                                                        when => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[2], Behavior.SkippedStep)
    end

    @testset "Execute a two-step scenario; Both steps succeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], Behavior.SuccessfulStepExecution)
    end

    @testset "Execute a three-step scenario; All steps succeeed; All results are Success" begin
        given = Given("Some precondition")
        when = When("some action")
        then = Then("some postcondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition,
                                                        when => successful_step_definition,
                                                        then => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given, when, then])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[2], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult.steps[3], Behavior.SuccessfulStepExecution)
    end

    @testset "Execute a scenario; Scenario is provided; Scenario is returned with the result" begin
        given = Given("Some precondition")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("This is a scenario", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test scenarioresult.scenario == scenario
    end

    @testset "Execute a scenario; No unique step definition found; Result is NonUniqueMatch" begin
        stepdefmatcher = ThrowingStepDefinitionMatcher(Behavior.NonUniqueStepDefinition([]))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[Given("some precondition")])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.NonUniqueMatch)
    end

    @testset "Execute a ScenarioOutline; Outline has two examples; Two scenarios are returned" begin
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], [["1"], ["2"]])
        step1 = Given("step 1")
        step2 = Given("step 2")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                        step2 => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)

        outlineresult = Behavior.executescenario(executor, [Background()], outline)

        @test length(outlineresult) == 2
    end

    @testset "Execute a ScenarioOutline; Outline has a successful and a failing example; First is success, second is fail" begin
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], [["1"], ["2"]])
        step1 = Given("step 1")
        step2 = Given("step 2")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                        step2 => failed_step_definition))
        executor = Behavior.Executor(stepdefmatcher)

        outlineresult = Behavior.executescenario(executor, [Background()], outline)

        @test outlineresult[1].steps[1] isa Behavior.SuccessfulStepExecution
        @test outlineresult[2].steps[1] isa Behavior.StepFailed
    end

    @testset "Execute a ScenarioOutline; Outline has three examples; Three scenarios are returned" begin
        outline = ScenarioOutline("", String[], ScenarioStep[Given("step <stepnumber>")], ["stepnumber"], [["1"], ["2"], ["3"]])
        step1 = Given("step 1")
        step2 = Given("step 2")
        step3 = Given("step 3")
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(step1 => successful_step_definition,
                                                        step2 => successful_step_definition,
                                                        step3 => successful_step_definition))
        executor = Behavior.Executor(stepdefmatcher)

        outlineresult = Behavior.executescenario(executor, [Background()], outline)

        @test length(outlineresult) == 3
    end

    @testset "Block text" begin
        @testset "Scenario step has a block text; Context contains the block text" begin
            given = Given("Some precondition", block_text="Some block text")
            function check_block_text_step_definition(context::StepDefinitionContext, _args)
                if context[:block_text] == "Some block text"
                    Behavior.SuccessfulStepExecution()
                else
                    Behavior.StepFailed("")
                end
            end
            stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => check_block_text_step_definition))
            executor = Behavior.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[given])

            scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

            @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
        end

        @testset "First step has block text, but second doesn't; The block text is cleared in the second step" begin
            given = Given("Some precondition", block_text="Some block text")
            when = When("some action")
            function check_block_text_step_definition(context::StepDefinitionContext, _args)
                if context[:block_text] == ""
                    Behavior.SuccessfulStepExecution()
                else
                    Behavior.StepFailed("")
                end
            end
            stepdefmatcher = FakeStepDefinitionMatcher(Dict(
                given => successful_step_definition,
                when => check_block_text_step_definition))
            executor = Behavior.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], [given, when])

            scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

            @test isa(scenarioresult.steps[2], Behavior.SuccessfulStepExecution)
        end
    end

    @testset "Backgrounds" begin
        @testset "Execute a one-step Background; No matching step found; Result is NoStepDefinitionFound" begin
            given = Given("some precondition")
            stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => successful_step_definition))

            background = Background("A background", ScenarioStep[Given("some background precondition")])

            executor = Behavior.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[Given("some precondition")])

            scenarioresult = Behavior.executescenario(executor, [background], scenario)
            # There is only one background in this test.
            backgroundresult = scenarioresult.backgroundresults[1]

            # Check the first step in the background result.
            @test isa(backgroundresult[1], Behavior.NoStepDefinitionFound)
        end

        @testset "Execute a one-step Background; A successful match found; Background result is Success" begin
            given = Given("some precondition")
            bgiven = Given("some background precondition")
            stepdefmatcher = FakeStepDefinitionMatcher(
                Dict(
                    given => successful_step_definition,
                    bgiven => successful_step_definition,
                ))

            background = Background("A background", ScenarioStep[Given("some background precondition")])

            executor = Behavior.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[Given("some precondition")])

            scenarioresult = Behavior.executescenario(executor, [background], scenario)
            # There is only one background in this test.
            backgroundresult = scenarioresult.backgroundresults[1]

            @test isa(backgroundresult[1], Behavior.SuccessfulStepExecution)
        end

        @testset "Execute a one-step background; The matching step fails; Result is Failed" begin
            given = Given("Some precondition")
            bgiven = Given("some background precondition")
            stepdefmatcher = FakeStepDefinitionMatcher(
                Dict(
                    given => successful_step_definition,
                    bgiven => failed_step_definition,
                ))
            executor = Behavior.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[given])
            background = Background("Background description", ScenarioStep[bgiven])

            scenarioresult = Behavior.executescenario(executor, [background], scenario)
            # There is only one background in this test.
            backgroundresult = scenarioresult.backgroundresults[1]

            @test isa(backgroundresult[1], Behavior.StepFailed)
        end

        @testset "Execute a one-step background; The background step fails; The Scenario step is skipped" begin
            given = Given("Some precondition")
            bgiven = Given("some background precondition")
            stepdefmatcher = FakeStepDefinitionMatcher(
                Dict(
                    given => successful_step_definition,
                    bgiven => failed_step_definition,
                ))
            executor = Behavior.Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[given])
            background = Background("Background description", ScenarioStep[bgiven])

            scenarioresult = Behavior.executescenario(executor, [background], scenario)

            @test isa(scenarioresult.steps[1], Behavior.SkippedStep)
        end

        # TODO Additional tests to ensure that Backgrounds work as any Scenario section does
    end
end
