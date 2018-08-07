using ExecutableSpecifications:
    Engine, QuietRealTimePresenter, FromMacroStepDefinitionMatcher,
    addmatcher!, runfeature!, finish, issuccess
using ExecutableSpecifications.Gherkin: Feature, FeatureHeader, Scenario, Given

@testset "Engine               " begin
    # Beware: This test actually exercises far too much of the code. It should be isolated to
    # `Engine`` only.
    @testset "Run a successful feature; Result is successful" begin
        # Arrange
        engine = Engine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "successful step" begin end
        """)
        addmatcher!(engine, matcher)

        successfulscenario = Scenario("", [], [Given("successful step")])
        feature = Feature(FeatureHeader("", [], []), [successfulscenario])

        # Act
        runfeature!(engine, feature)

        # Assert
        result = finish(engine)
        @test issuccess(result)
    end

    @testset "Run a failing feature; Result is not successful" begin
        # Arrange
        engine = Engine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "failing step" begin
                @expect 1 == 2
            end
        """)
        addmatcher!(engine, matcher)

        failingscenario = Scenario("", [], [Given("failing step")])
        feature = Feature(FeatureHeader("", [], []), [failingscenario])

        # Act
        runfeature!(engine, feature)

        # Assert
        result = finish(engine)
        @test !issuccess(result)
    end

    @testset "Run a failing and a successful feature; Result is not successful" begin
        # Arrange
        engine = Engine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "failing step" begin
                @expect 1 == 2
            end

            @given "successful step" begin end
        """)
        addmatcher!(engine, matcher)

        failingscenario = Scenario("", [], [Given("failing step")])
        successfulscenario = Scenario("", [], [Given("successful step")])
        feature1 = Feature(FeatureHeader("fails", [], []), [failingscenario])
        feature2 = Feature(FeatureHeader("succeeds", [], []), [successfulscenario])

        # Act
        runfeature!(engine, feature1)
        runfeature!(engine, feature2)

        # Assert
        result = finish(engine)
        @test !issuccess(result)
    end
end