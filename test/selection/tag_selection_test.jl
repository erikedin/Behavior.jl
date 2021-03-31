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

    @testset "Empty selector; @foo matches" begin
        # Arrange
        selector = parsetagselector("")

        # Act and Assert
        @test select(selector, String["@foo"])
    end

    @testset "Empty selector; select returns true for no tags" begin
        # Arrange
        selector = parsetagselector("")

        # Act and Assert
        @test select(selector, String[])
    end

    @testset "Only white space selector; select returns true for no tags and @foo" begin
        # Arrange
        selector = parsetagselector("  ")

        # Act and Assert
        @test select(selector, String[])
        @test select(selector, String["@foo"])
    end
end