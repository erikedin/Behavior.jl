using ExecutableSpecifications:
    Engine, QuietRealTimePresenter, FromMacroStepDefinitionMatcher,
    addmatcher, runfeature, finish, issuccess
using ExecutableSpecifications.Gherkin: Feature, FeatureHeader, Scenario, Given

@testset "Engine" begin
    # Beware: This test actually exercises far too much of the code. It should be isolated to
    # `Engine`` only.
    @testset "Run a successful feature; Result is successful" begin
        # Arrange
        engine = Engine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "successful step" begin end
        """)
        addmatcher(engine, matcher)

        successfulscenario = Scenario("", [], [Given("successful step")])
        feature = Feature(FeatureHeader("", [], []), [successfulscenario])

        # Act
        runfeature(engine, feature)

        # Assert
        result = finish(engine)
        @test issuccess(result)
    end
end