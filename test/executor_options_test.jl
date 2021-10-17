using Behavior.Gherkin.Experimental
using Behavior: ExecutorEngine, FromMacroStepDefinitionMatcher
using Behavior: addmatcher!, runfeature!, finish, issuccess

@testset "Executor options     " begin
    @testset "Don't keep going: Run a failing feature; Other step not executed" begin
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
                
                Scenario: This will not run with keepgoing=false
                    Given ok step
        """)
        parser = FeatureFileParser()
        parseresult = parser(source)
        feature = parseresult.value

        # Act
        runfeature!(engine, feature; keepgoing=false)

        # Assert
        result = finish(engine)
        @test !issuccess(result)
        @test result.features[1].n_failure == 1
        @test result.features[1].n_success == 0
    end

    @testset "Keep going: Run a failing feature; Other step executed" begin
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
        @test result.features[1].n_success == 1
    end
end