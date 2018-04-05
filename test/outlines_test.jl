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
end