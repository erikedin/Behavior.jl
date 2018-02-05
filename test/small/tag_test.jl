using Base.Test
using BDD: hastag

@testset "Tags" begin
    @testset "Feature tags" begin
        @testset "@tag1 is applied to a feature; The parsed feature has @tag1" begin
            text = """
            @tag1
            Feature: Some description
            """

            result = parsefeature(text)
            
            @test issuccessful(result)
            @test hastag(result.value, "@tag1")
        end

        @testset "Feature without tags; The parsed feature does not have @tag1" begin
            text = """
            Feature: Some description
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test hastag(result.value, "@tag1") == false
        end

        @testset "Feature with multiple tags; The parsed feature has all tags" begin
            text = """
            @tag1 @tag2 @tag3
            Feature: Some description
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test hastag(result.value, "@tag1")
            @test hastag(result.value, "@tag2")
            @test hastag(result.value, "@tag3")
        end
    end

    @testset "Scenario tags" begin
        @testset "Scenario has one tag; The parsed scenario has tag1" begin
            text = """
            Feature: Some description

                @tag1
                Scenario: Some description
                    Given a precondition
            """

            result = parsefeature(text)
            
            @test issuccessful(result)
            @test hastag(result.value.scenarios[1], "@tag1")
        end

        @testset "Scenario has no tags; The parsed scenario does not have tag1" begin
            text = """
            Feature: Some description

                Scenario: Some description
                    Given a precondition
            """

            result = parsefeature(text)
            
            @test issuccessful(result)
            @test hastag(result.value.scenarios[1], "@tag1") == false
        end
    end
end