using Base.Test
using ExecutableSpecifications
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications: transformoutline

@testset "Scenario Outline" begin
    @testset "Transform; Scenario Outline has one example; One Scenario" begin
        outline = ScenarioOutline("", [],
            [Given("placeholder <foo>")],
            ["foo"],
            Array{String}(["bar"]))

        scenarios = transformoutline(outline)

        @test length(scenarios) == 1
        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder bar")
    end

    @testset "Transform; Placeholder is quux; quux is replaced by example" begin
        outline = ScenarioOutline("", [],
            [Given("placeholder <quux>")],
            ["quux"],
            Array{String}(["baz"]))

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
    end
end