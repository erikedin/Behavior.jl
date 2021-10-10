using Behavior.Gherkin.Experimental
using Behavior: ExecutorEngine, FromMacroStepDefinitionMatcher
using Behavior: addmatcher!, runfeature!, finish, issuccess

@testset "Executor options" begin
    @testset "Run a failing feature; Result is not successful" begin
        # Arrange
        engine = ExecutorEngine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("ok step") do context
            end

            @given("failing step") do context
                @expect 1 == 2
            end
        """)
        addmatcher!(engine, matcher)

        source = ParserInput("""
            Feature: Fails first scenario

                Scenario: This fails
                    Given failing step
                
                Scenario: This will not run with keepgoing=true
                    Given ok step
        """)
        parser = FeatureFileParser()
        parseresult = parser(source)
        feature = parseresult.value

        # Act
        runfeature!(engine, feature; keepgoing=true)

        # Assert
        result = finish(engine)
        @test !issuccess(result)
        @test result.features[1].n_failure == 1
        @test result.features[1].n_success == 0
    end
end