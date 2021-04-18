using Behavior: findmissingsteps, ExecutorEngine, suggestmissingsteps

@testset "Suggestions          " begin
    @testset "Find missing steps" begin
        @testset "One step missing; Step is listed as missing in result" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior
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
                using Behavior
            
                @given("some step") do context end
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
                using Behavior

                @given("some precondition") do context end
                @when("some action") do context end
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

        @testset "Two scenarios, two missing steps; Missing steps from both scenarios listed" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("some precondition") do context end
            """)

            executor = Executor(matcher, QuietRealTimePresenter())

            scenario1 = Scenario("1", String[], ScenarioStep[Given("some missing step")])
            scenario2 = Scenario("2", String[], ScenarioStep[Given("some other missing step")])
            feature = Feature(FeatureHeader("", [], []), [scenario1, scenario2])

            # Act
            result = findmissingsteps(executor, feature)

            # Assert
            @test Given("some missing step") in result
            @test Given("some other missing step") in result
        end

        @testset "Two scenarios, one missing step; Step is only listed once" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("some precondition") do context end
            """)

            executor = Executor(matcher, QuietRealTimePresenter())

            scenario1 = Scenario("1", String[], ScenarioStep[Given("some missing step")])
            scenario2 = Scenario("2", String[], ScenarioStep[Given("some missing step")])
            feature = Feature(FeatureHeader("", [], []), [scenario1, scenario2])

            # Act
            result = findmissingsteps(executor, feature)

            # Assert
            @test result == [Given("some missing step")]
        end

        @testset "Background has a missing step; Missing step is listed" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("some precondition") do context end
            """)

            executor = Executor(matcher, QuietRealTimePresenter())

            background = Background("", ScenarioStep[Given("some missing step")])
            scenario1 = Scenario("1", String[], ScenarioStep[Given("some precondition")])
            feature = Feature(FeatureHeader("", [], []), background, [scenario1])

            # Act
            result = findmissingsteps(executor, feature)

            # Assert
            @test result == [Given("some missing step")]
        end

        @testset "Two missing steps with different block texts; Step is only listed once" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("some precondition") do context end
            """)

            executor = Executor(matcher, QuietRealTimePresenter())

            scenario1 = Scenario("1", String[], ScenarioStep[Given("some missing step"; block_text="1")])
            scenario2 = Scenario("2", String[], ScenarioStep[Given("some missing step"; block_text="2")])
            feature = Feature(FeatureHeader("", [], []), [scenario1, scenario2])

            # Act
            result = findmissingsteps(executor, feature)

            # Assert
            @test length(result) == 1
        end
    end

    @testset "Suggestions" begin
        @testset "One missing step; Add step according to suggestion; Step is found" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("successful step") do context end
            """)
            executor = Executor(matcher, QuietRealTimePresenter())

            scenario1 = Scenario("1", String[], ScenarioStep[Given("missing step")])
            feature = Feature(FeatureHeader("", [], []), [scenario1])

            # Act
            missingstepscode = suggestmissingsteps(executor, feature)

            # Assert
            missingmatcher = FromMacroStepDefinitionMatcher(missingstepscode)
            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher)
            addmatcher!(compositematcher, missingmatcher)

            assertexecutor = Executor(compositematcher, QuietRealTimePresenter())

            result = findmissingsteps(assertexecutor, feature)
            @test result == []
        end
        
        @testset "Many missing steps; Add steps according to suggestion; Steps are found" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("successful step") do context end
            """)
            executor = Executor(matcher, QuietRealTimePresenter())

            missingsteps = ScenarioStep[
                Given("missing given"),
                When("missing when"),
                Then("missing then"),
            ]
            scenario1 = Scenario("1", String[], missingsteps)
            feature = Feature(FeatureHeader("", [], []), [scenario1])

            # Act
            missingstepscode = suggestmissingsteps(executor, feature)

            # Assert
            missingmatcher = FromMacroStepDefinitionMatcher(missingstepscode)
            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher)
            addmatcher!(compositematcher, missingmatcher)

            assertexecutor = Executor(compositematcher, QuietRealTimePresenter())

            result = findmissingsteps(assertexecutor, feature)
            @test result == []
        end

        @testset "Missing step ending with a double-quote; Suggestion works" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior

                @given("successful step") do context end
            """)
            executor = Executor(matcher, QuietRealTimePresenter())

            missingsteps = ScenarioStep[
                Given("missing given\""),
            ]
            scenario1 = Scenario("1", String[], missingsteps)
            feature = Feature(FeatureHeader("", [], []), [scenario1])

            # Act
            missingstepscode = suggestmissingsteps(executor, feature)

            # Assert
            missingmatcher = FromMacroStepDefinitionMatcher(missingstepscode)
            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher)
            addmatcher!(compositematcher, missingmatcher)

            assertexecutor = Executor(compositematcher, QuietRealTimePresenter())

            result = findmissingsteps(assertexecutor, feature)
            @test result == []
        end

        @testset "One missing step; Add step according to suggestion; Step fails when executed" begin
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior
            """)
            executor = Executor(matcher, QuietRealTimePresenter())

            scenario1 = Scenario("1", String[], ScenarioStep[Given("missing step")])
            feature = Feature(FeatureHeader("", [], []), [scenario1])

            # Act
            missingstepscode = suggestmissingsteps(executor, feature)

            # Assert
            missingmatcher = FromMacroStepDefinitionMatcher(missingstepscode)
            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher)
            addmatcher!(compositematcher, missingmatcher)

            assertexecutor = Executor(compositematcher, QuietRealTimePresenter())

            featureresult = Behavior.executefeature(assertexecutor, feature)
            scenarioresult = featureresult.scenarioresults[1]
            @test scenarioresult.steps[1] isa Behavior.StepFailed
        end
    end

    @testset "Escaping PCRE metacharacters" begin
        function testsuggestionescaping(steps::AbstractVector{ScenarioStep})
            # Arrange
            matcher = FromMacroStepDefinitionMatcher("""
                using Behavior
            """)
            executor = Executor(matcher, QuietRealTimePresenter())

            scenario1 = Scenario("1", String[], steps)
            feature = Feature(FeatureHeader("", [], []), [scenario1])

            # Act
            missingstepscode = suggestmissingsteps(executor, feature)

            # Assert
            missingmatcher = FromMacroStepDefinitionMatcher(missingstepscode)
            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher)
            addmatcher!(compositematcher, missingmatcher)

            assertexecutor = Executor(compositematcher, QuietRealTimePresenter())

            featureresult = Behavior.executefeature(assertexecutor, feature)
            scenarioresult = featureresult.scenarioresults[1]
            @test scenarioresult.steps[1] isa Behavior.StepFailed
        end

        # Check that each PCRE metacharacter is escaped properly.
        # We do this by implementing the suggested step and check that it doesn't
        # throw an unexpected exception and that it can be found. If any metacharacter is
        # unescaped, one of those two things will happen, with at least one exception: the period.
        #
        # Since the step, like
        #   Given some step with (parentheses)
        # will be converted into a regex, we want those parentheses to be
        # escaped, so they are treated as the () themselves, not the regex
        # metacharacter.
        #
        # Note: Since . matches itself we can't use the same test as for everything else,
        # since a step
        #   Given some step with . in it
        # will match regardless if it's escaped or not, this means that we must instead test
        # that it _does not match_
        #   Given some step with x in it
        # which will ensure that the . is escaped.
        for (steps, testdescription) in [
                # Check that $ is escaped properly
                (ScenarioStep[Given("some step \$x")], "\$"),

                # Check ^
                (ScenarioStep[Given("some ^")], "^"),

                # Check ()
                (ScenarioStep[Given("some (and some)")], "parentheses"),

                # Check |
                (ScenarioStep[Given("some (x|y) or")], "pipe"),

                # Check []
                (ScenarioStep[Given("some [or]")], "square brackets"),

                # Check ?
                (ScenarioStep[Given("some question?")], "question mark"),

                # Check *
                (ScenarioStep[Given("some *")], "*"),

                # Check +
                (ScenarioStep[Given("some +")], "+"),

                # Check {}
                (ScenarioStep[Given("some {")], "{"),
                (ScenarioStep[Given("some }")], "}"),
            ]

            @testset "Escaping regular expressions characters: $testdescription" begin
                testsuggestionescaping(steps)
            end
        end
    end

    @testset "Escaping the PCRE metacharacter ." begin
        # Arrange
        matcher = FromMacroStepDefinitionMatcher("""
            using Behavior
        """)
        executor = Executor(matcher, QuietRealTimePresenter())

        steps = ScenarioStep[
            Given("some step with a . in it")
        ]
        scenario1 = Scenario("1", String[], steps)
        feature = Feature(FeatureHeader("", [], []), [scenario1])

        # Act
        missingstepscode = suggestmissingsteps(executor, feature)

        # Assert
        # Ensure that the step
        #   Given some step with a x in it
        # _does not_ have a matching step.
        missingmatcher = FromMacroStepDefinitionMatcher(missingstepscode)
        compositematcher = CompositeStepDefinitionMatcher()
        addmatcher!(compositematcher, matcher)
        addmatcher!(compositematcher, missingmatcher)

        assertexecutor = Executor(compositematcher, QuietRealTimePresenter())

        shouldbemissing = Given("some step with a x in it")
        newscenario = Scenario("1", String[], ScenarioStep[shouldbemissing])
        newfeature = Feature(FeatureHeader("", [], []), [newscenario])
        result = findmissingsteps(assertexecutor, newfeature)

        @test shouldbemissing in result
    end
end