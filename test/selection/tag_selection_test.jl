using Test
using ExecutableSpecifications.Selection

@testset "Selection            " begin
    @testset "Selector is a single tag; Select returns true for that that" begin
        # Arrange
        selector = parsetagselector("@foo")

        # Act and Assert
        @test select(selector, ["@foo"])
    end

    @testset "Selector is a single tag; Select returns false for no tags" begin
        # Arrange
        selector = parsetagselector("@foo")

        # Act and Assert
        @test select(selector, String[]) == false
    end

    @testset "Selector is a single tag; Select returns false for a different tag" begin
        # Arrange
        selector = parsetagselector("@foo")

        # Act and Assert
        @test select(selector, String["@bar"]) == false
    end

    @testset "Selector is a single tag @bar; Select returns false for a different tag @foo" begin
        # Arrange
        selector = parsetagselector("@bar")

        # Act and Assert
        @test select(selector, String["@foo"]) == false
    end

    @testset "Selector is a single tag; Scenario has @foo as the second tag; select returns true" begin
        # Arrange
        selector = parsetagselector("@foo")

        # Act and Assert
        @test select(selector, ["@bar", "@foo"])
    end

    @testset "Selector is not @foo; Scenario has no tags; select returns true" begin
        # Arrange
        selector = parsetagselector("not @foo")

        # Act and Assert
        @test select(selector, String[])
    end
end