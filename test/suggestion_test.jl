using ExecutableSpecifications: findmissingsteps

@testset "Suggestions          " begin
    @testset "One step missing; Step is listed as missing in result" begin
        # Arrange
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications
        """)

        executor = Executor(matcher, QuietRealTimePresenter())

        missinggiven = Given("some step")
        successfulscenario = Scenario("", String[], ScenarioStep[missinggiven])
        feature = Feature(FeatureHeader("", [], []), [successfulscenario])

        # Act
        result = findmissingsteps(executor, feature)

        # Assert
        @test missinggiven in result
    end

    @testset "No step missing; Step is not listed as missing in result" begin
        # Arrange
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications
            
            @given "some step" begin end
        """)

        executor = Executor(matcher, QuietRealTimePresenter())

        given = Given("some step")
        successfulscenario = Scenario("", String[], ScenarioStep[given])
        feature = Feature(FeatureHeader("", [], []), [successfulscenario])

        # Act
        result = findmissingsteps(executor, feature)

        # Assert
        @test !(given in result)
    end

    @testset "One step missing, two found; Only missing step is listed" begin
        # Arrange
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "some precondition" begin end
            @when "some action" begin end
        """)

        executor = Executor(matcher, QuietRealTimePresenter())

        steps = [
            Given("some missing step"),
            Given("some precondition"),
            When("some action"),
        ]
        successfulscenario = Scenario("", String[], steps)
        feature = Feature(FeatureHeader("", [], []), [successfulscenario])

        # Act
        result = findmissingsteps(executor, feature)

        # Assert
        @test Given("some missing step") in result
        @test !(Given("some precondition") in result)
        @test !(When("some action") in result)
    end
end