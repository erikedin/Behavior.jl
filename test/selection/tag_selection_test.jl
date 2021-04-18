using Test
using Behavior.Selection
using Behavior.Gherkin
using Behavior.Gherkin: AbstractScenario

@testset "Selection            " begin
    # These tests check that the tag selector is parsed and that the expressions are used
    # properly. It uses only tags on scenarios to check this, for simplicity. Tests in a
    # section below check that tags are inherited properly between features and scenarios.
    @testset "Tag selector" begin
        @testset "Feature has tag @foo and no scenarios; Selecting @foo returns no scenarios" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @foo and one scenario; selecting @foo returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags and no scenarios; select @foo returns no scenarios" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], String[])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @bar; Select for @foo returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @foo; Select for @bar returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@bar")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tags @bar and @foo; Select for @foo returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar", "@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags; Selector is (not @foo); select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has tag @foo; Selector is (not @foo); select returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @foo; Empty selector; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags; Empty selector; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags; Selector is only whitespace; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("   ")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has tag @baz; Selector is only whitespace; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("   ")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end
    end

    # These tests check that tags are inherited properly between features and scenarios.
    # It assumes that the parsing of tag selectors works as intended, tested above.
    @testset "Feature and Scenario selection" begin
        @testset "Feature has tag @foo and one scenario, no tags; select returns the feature with one scenario" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[])
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Only one scenario has tag @bar; select returns the feature with only that scenario" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String["@bar"], ScenarioStep[]),
                Scenario("Some other scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@bar")
            newfeature = select(selector, feature)

            # Assert
            @test length(newfeature.scenarios) == 1
            @test newfeature.scenarios[1] == feature.scenarios[1]
        end

        @testset "One scenario has tag @ignore; selecting on (not @ignore) returns only the feature without that tag" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String["@ignore"], ScenarioStep[]),
                Scenario("Some other scenario", String["@other"], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @ignore")
            newfeature = select(selector, feature)

            # Assert
            @test length(newfeature.scenarios) == 1
            @test newfeature.scenarios[1] == feature.scenarios[2]
        end
    end
end