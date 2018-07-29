using ExecutableSpecifications
using ExecutableSpecifications: StepDefinitionMatcher
using ExecutableSpecifications: Executor, executescenario, @expect, SuccessfulStepExecution
using ExecutableSpecifications: issuccess

mutable struct FakeExecutionEnvironment <: ExecutableSpecifications.ExecutionEnvironment
    afterscenariowasexecuted::Bool

    FakeExecutionEnvironment() = new(false)
end

function ExecutableSpecifications.beforescenario(::FakeExecutionEnvironment, context::StepDefinitionContext, scenario::Gherkin.Scenario)
    context[:beforescenariowasexecuted] = true
end

function ExecutableSpecifications.afterscenario(f::FakeExecutionEnvironment, context::StepDefinitionContext, scenario::Gherkin.Scenario)
    context[:afterscenariowasexecuted] = true
    f.afterscenariowasexecuted = true
end

struct SingleStepDefinitionMatcher <: StepDefinitionMatcher
    stepbody::Function
end

function ExecutableSpecifications.findstepdefinition(
        s::SingleStepDefinitionMatcher,
        step::ExecutableSpecifications.Gherkin.ScenarioStep)
    stepdefinition = context -> begin
        s.stepbody(context)
        SuccessfulStepExecution()
    end
    StepDefinition("some text", stepdefinition, StepDefinitionLocation("", 0))
end

@testset "Execution Environment" begin
    @testset "Scenario Execution Environment" begin
        @testset "beforescenario is defined; beforescenario is executed before the scenario" begin
            # Arrange
            env = FakeExecutionEnvironment()

            # This step definition tests that the symbol :beforescenariowasexecuted is present in
            # the context at execution time. This symbol should be set by the
            # FakeExecutionEnvironment.
            stepdefmatcher = SingleStepDefinitionMatcher(context -> @assert context[:beforescenariowasexecuted])
            executor = Executor(stepdefmatcher; executionenv=env)
            scenario = Scenario("Description", [], [Given("")])

            # Act
            result = executescenario(executor, scenario)

            # Assert
            @test issuccess(result.steps[1])
        end

        @testset "beforescenario is the default noop; beforescenario is not executed before the scenario" begin
            # Arrange
            stepdefmatcher = SingleStepDefinitionMatcher(context -> @assert !haskey(context, :beforescenariowasexecuted))
            executor = Executor(stepdefmatcher)
            scenario = Scenario("Description", [], [Given("")])

            # Act
            result = executescenario(executor, scenario)

            # Assert
            @test issuccess(result.steps[1])
        end

        @testset "afterscenario is defined; afterscenario has not been called at scenario execution" begin
            # Arrange
            env = FakeExecutionEnvironment()

            # This step definition tests that the symbol :beforescenariowasexecuted is present in
            # the context at execution time. This symbol should be set by the
            # FakeExecutionEnvironment.
            stepdefmatcher = SingleStepDefinitionMatcher(context -> @assert !haskey(context, :afterscenariowasexecuted))
            executor = Executor(stepdefmatcher; executionenv=env)
            scenario = Scenario("Description", [], [Given("")])

            # Act
            result = executescenario(executor, scenario)

            # Assert
            @test issuccess(result.steps[1])
        end


        @testset "afterscenario is defined; afterscenario is called" begin
            # Arrange
            env = FakeExecutionEnvironment()

            # This step definition tests that the symbol :beforescenariowasexecuted is present in
            # the context at execution time. This symbol should be set by the
            # FakeExecutionEnvironment.
            stepdefmatcher = SingleStepDefinitionMatcher(context -> nothing)
            executor = Executor(stepdefmatcher; executionenv=env)
            scenario = Scenario("Description", [], [Given("")])

            # Act
            result = executescenario(executor, scenario)

            # Assert
            @test env.afterscenariowasexecuted
        end
    end
end