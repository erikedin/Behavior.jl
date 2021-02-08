using ExecutableSpecifications.Gherkin: issuccessful, parsescenario!, Given, When, Then, ByLineParser, ScenarioStep, ParseOptions

@testset "Data tables          " begin
    @testset "A Scenario with a data table; The data table is associated with the step" begin
        text = """
        Scenario: Data tables
            When some action
            Then some tabular data
                | header 1 | header 2 |
                | foo 1    | bar 1    |
                | foo 2    | bar 2    |
                | foo 3    | bar 3    |
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps[2].datatable == [
            ["header 1", "header 2"],
            ["foo 1", "bar 1"],
            ["foo 2", "bar 2"],
            ["foo 3", "bar 3"],
        ]
    end
end