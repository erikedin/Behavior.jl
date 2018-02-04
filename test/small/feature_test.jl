using BDD: parsefeature, issuccessful

@testset "Feature" begin
    @testset "Parse feature" begin
        @testset "Read feature description; Description matches input" begin
            text = """
            Feature: This is a feature
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test result.value.description == "This is a feature"
        end
    end
end