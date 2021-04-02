using Test
using ExecutableSpecifications.Selection
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications.Gherkin: AbstractScenario

@testset "Selection            " begin
    @testset "Tag selector" begin
        @testset "Feature has tag @foo and no scenarios; select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end

        @testset "Feature has no tags and no scenarios; select returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], String[])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature === nothing
        end

        @testset "Feature has tag @bar; Select for @foo returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature === nothing
        end

        @testset "Feature has tag @foo; Select for @bar returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@bar")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature === nothing
        end

        @testset "Feature has tags @bar and @foo; Select for @foo returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar", "@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end

        @testset "Feature has no tags; Selector is (not @foo); select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("not @foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end

        @testset "Feature has tag @foo; Selector is (not @foo); select returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("not @foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature === nothing
        end

        @testset "Feature has tag @foo; Empty selector; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end

        @testset "Feature has no tags; Empty selector; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end

        @testset "Feature has no tags; Selector is only whitespace; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("   ")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end

        @testset "Feature has tag @baz; Selector is only whitespace; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("   ")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature == feature
        end
    end
end