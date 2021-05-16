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

using Behavior
using Behavior:
    StepDefinitionMatcher,
    Executor, executescenario, @expect, SuccessfulStepExecution,
    issuccess, beforescenario, afterscenario, FromSourceExecutionEnvironment


mutable struct FakeExecutionEnvironment <: Behavior.ExecutionEnvironment
    afterscenariowasexecuted::Bool

    FakeExecutionEnvironment() = new(false)
end

function Behavior.beforescenario(::FakeExecutionEnvironment, context::StepDefinitionContext, scenario::Gherkin.Scenario)
    context[:beforescenariowasexecuted] = true
end

function Behavior.afterscenario(f::FakeExecutionEnvironment, context::StepDefinitionContext, scenario::Gherkin.Scenario)
    context[:afterscenariowasexecuted] = true
    f.afterscenariowasexecuted = true
end

struct SingleStepDefinitionMatcher <: StepDefinitionMatcher
    stepbody::Function
end

function Behavior.findstepdefinition(
        s::SingleStepDefinitionMatcher,
        step::Behavior.Gherkin.ScenarioStep)
    stepdefinition = (context, args) -> begin
        s.stepbody(context, args)
        SuccessfulStepExecution()
    end
    StepDefinitionMatch(StepDefinition("some text", stepdefinition, StepDefinitionLocation("", 0)))
end

@testset "Execution Environment" begin
    @testset "Scenario Execution Environment" begin
        @testset "beforescenario is defined; beforescenario is executed before the scenario" begin
            # Arrange
            env = FakeExecutionEnvironment()

            # This step definition tests that the symbol :beforescenariowasexecuted is present in
            # the context at execution time. This symbol should be set by the
            # FakeExecutionEnvironment.
            stepdefmatcher = SingleStepDefinitionMatcher((context, args) -> @assert context[:beforescenariowasexecuted])
            executor = Executor(stepdefmatcher; executionenv=env)
            scenario = Scenario("Description", String[], ScenarioStep[Given("")])

            # Act
            result = executescenario(executor, Background(), scenario)

            # Assert
            @test issuccess(result.steps[1])
        end

        @testset "beforescenario is the default noop; beforescenario is not executed before the scenario" begin
            # Arrange
            stepdefmatcher = SingleStepDefinitionMatcher((context, args) -> @assert !haskey(context, :beforescenariowasexecuted))
            executor = Executor(stepdefmatcher)
            scenario = Scenario("Description", String[], ScenarioStep[Given("")])

            # Act
            result = executescenario(executor, Background(), scenario)

            # Assert
            @test issuccess(result.steps[1])
        end

        @testset "afterscenario is defined; afterscenario has not been called at scenario execution" begin
            # Arrange
            env = FakeExecutionEnvironment()

            # This step definition tests that the symbol :beforescenariowasexecuted is present in
            # the context at execution time. This symbol should be set by the
            # FakeExecutionEnvironment.
            stepdefmatcher = SingleStepDefinitionMatcher((context, args) -> @assert !haskey(context, :afterscenariowasexecuted))
            executor = Executor(stepdefmatcher; executionenv=env)
            scenario = Scenario("Description", String[], ScenarioStep[Given("")])

            # Act
            result = executescenario(executor, Background(), scenario)

            # Assert
            @test issuccess(result.steps[1])
        end


        @testset "afterscenario is defined; afterscenario is called" begin
            # Arrange
            env = FakeExecutionEnvironment()

            # This step definition tests that the symbol :beforescenariowasexecuted is present in
            # the context at execution time. This symbol should be set by the
            # FakeExecutionEnvironment.
            stepdefmatcher = SingleStepDefinitionMatcher((context, args) -> nothing)
            executor = Executor(stepdefmatcher; executionenv=env)
            scenario = Scenario("Description", String[], ScenarioStep[Given("")])

            # Act
            result = executescenario(executor, Background(), scenario)

            # Assert
            @test env.afterscenariowasexecuted
        end
    end

    @testset "FromSourceExecutionEnvironment" begin
        @testset "beginscenario is defined in source; beginscenario is executed" begin
            # Arrange
            env = FromSourceExecutionEnvironment("""
                using Behavior

                @beforescenario begin
                    context[:beforescenariowasexecuted] = true
                end
            """)

            context = StepDefinitionContext()
            scenario = Gherkin.Scenario("", String[], ScenarioStep[])

            # Act
            beforescenario(env, context, scenario)

            # Assert
            @test context[:beforescenariowasexecuted]
        end

        @testset "No beginscenario is defined in source; beginscenario is a noop" begin
            # Arrange
            env = FromSourceExecutionEnvironment("")

            context = StepDefinitionContext()
            scenario = Gherkin.Scenario("", String[], ScenarioStep[])

            # Act
            beforescenario(env, context, scenario)

            # Assert
            @test !haskey(context, :beforescenariowasexecuted)
        end

        @testset "afterscenario is defined in source; afterscenario is executed" begin
            # Arrange
            env = FromSourceExecutionEnvironment("""
                using Behavior

                @afterscenario begin
                    context[:afterscenariowasexecuted] = true
                end
            """)

            context = StepDefinitionContext()
            scenario = Gherkin.Scenario("", String[], ScenarioStep[])

            # Act
            afterscenario(env, context, scenario)

            # Assert
            @test context[:afterscenariowasexecuted]
        end

        @testset "No afterscenario is defined in source; afterscenario is a noop" begin
            # Arrange
            env = FromSourceExecutionEnvironment("")

            context = StepDefinitionContext()
            scenario = Gherkin.Scenario("", String[], ScenarioStep[])

            # Act
            afterscenario(env, context, scenario)

            # Assert
            @test !haskey(context, :afterscenariowasexecuted)
        end
    end
end