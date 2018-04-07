using Base.Test
using ExecutableSpecifications
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications: transformoutline

@testset "Scenario Outline" begin
    @testset "Transform; Outline description is \"Some description\"; Result description is same" begin
        outline = ScenarioOutline("Some description", [],
            [Given("placeholder <foo>")],
            ["foo"],
            [["bar"]])

        scenarios = transformoutline(outline)

        @test scenarios[1].description == "Some description"
    end

    @testset "Transform; Outline tags are @foo @bar; Result tags are @foo @bar" begin
        outline = ScenarioOutline("", ["@foo", "@bar"],
            [Given("some <foo>")],
            ["foo"],
            [["bar"]])

        scenarios = transformoutline(outline)

        @test scenarios[1].tags == ["@foo", "@bar"]
    end

    @testset "Transform; Scenario Outline has one example; One Scenario" begin
        outline = ScenarioOutline("", [],
            [Given("placeholder <foo>")],
            ["foo"],
            [["bar"]])

        scenarios = transformoutline(outline)

        @test length(scenarios) == 1
        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder bar")
    end

    @testset "Transform; Placeholder is quux; quux is replaced by example" begin
        outline = ScenarioOutline("", [],
            [Given("placeholder <quux>")],
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
    end

    @testset "Transform; Two placeholders foo, quux; foo and quux are replaced" begin
        outline = ScenarioOutline("", [],
            [Given("placeholders <foo> <quux>")],
            ["foo", "quux"],
            [["bar", "baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholders bar baz")
    end

    @testset "Transform; Steps Given and When; Both steps are transformed" begin
        steps = [Given("placeholder <quux>"), When("other <quux>")]
        outline = ScenarioOutline("", [],
            steps,
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
        @test scenario.steps[2] == When("other baz")
    end

    @testset "Transform; Steps Given and When again; Both steps are transformed" begin
        steps = [Given("placeholder <quux>"), When("another step <quux>")]
        outline = ScenarioOutline("", [],
            steps,
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Given("placeholder baz")
        @test scenario.steps[2] == When("another step baz")
    end

    @testset "Transform; Step Then; Step is transformed" begin
        steps = [Then("step <quux>")]
        outline = ScenarioOutline("", [],
            steps,
            ["quux"],
            [["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenario.steps[1] == Then("step baz")
    end

    @testset "Transform; Two examples; Two scenarios in the result" begin
        outline = ScenarioOutline("", [],
            [Given("step <quux>")],
            ["quux"],
            [["bar"], ["baz"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenarios[1].steps[1] == Given("step bar")
        @test scenarios[2].steps[1] == Given("step baz")
    end

    @testset "Transform; Placeholders in the block_text; Placeholders are replaced with examples" begin
        outline = ScenarioOutline("", [],
            [Given(""; block_text="given <quux>"),
             When(""; block_text="when <quux>"),
             Then(""; block_text="then <quux>")],
            ["quux"],
            [["bar"]])

        scenarios = transformoutline(outline)

        scenario = scenarios[1]
        @test scenarios[1].steps[1] == Given(""; block_text="given bar")
        @test scenarios[1].steps[2] == When(""; block_text="when bar")
        @test scenarios[1].steps[3] == Then(""; block_text="then bar")
    end

    # TODO: Mismatching placeholders
end