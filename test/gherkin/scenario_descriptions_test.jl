using ExecutableSpecifications.Gherkin: parsescenario!, issuccessful, Given, When, Then, ByLineParser, ScenarioStep

@testset "Scenario descriptions" begin
    @testset "Scenario long description, one line; Long description is available" begin
        text = """
        Scenario: Some description
            This is a longer description
            Given some precondition

            When some action

            Then some postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description"
    end

    @testset "Scenario long description, three lines; Long description is available" begin
        text = """
        Scenario: Some description
            This is a longer description
            This is another line.
            This is a third line.
            Given some precondition

            When some action

            Then some postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description\nThis is another line.\nThis is a third line."
    end

    @testset "Scenario with blank lines between description and steps; Trailing blank lines are ignored" begin
        text = """
        Scenario: Some description
            This is a longer description
            This is another line.
            This is a third line.

            Given some precondition

            When some action

            Then some postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description\nThis is another line.\nThis is a third line."
    end

    @testset "Scenario with blank lines in description; Blank lines in description are included" begin
        text = """
        Scenario: Some description
            This is a longer description

            This is another line.
            This is a third line.

            Given some precondition

            When some action

            Then some postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description\n\nThis is another line.\nThis is a third line."
    end

    @testset "Long description without steps; Zero steps and a long description" begin
        text = """
        Scenario: Some description
            NotAStep some more text
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)
        @test issuccessful(result)
        scenario = result.value

        @test isempty(scenario.steps)
        @test scenario.long_description == "NotAStep some more text"
    end
end

@testset "Outline descriptions" begin
    @testset "Scenario long description, one line; Long description is available" begin
        text = """
        Scenario Outline: Some description
            This is a longer description
            Given some precondition <foo>

            When some action

            Then some postcondition
        
        Examples:
            | foo |
            |  1  |
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description"
    end

    @testset "Scenario long description, three lines; Long description is available" begin
        text = """
        Scenario Outline: Some description
            This is a longer description
            This is another line.
            This is a third line.
            Given some precondition <foo>

            When some action

            Then some postcondition
        
        Examples:
            | foo |
            |  1  |
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description\nThis is another line.\nThis is a third line."
    end

    @testset "Scenario with blank lines between description and steps; Trailing blank lines are ignored" begin
        text = """
        Scenario Outline: Some description
            This is a longer description
            This is another line.
            This is a third line.

            Given some precondition <foo>

            When some action

            Then some postcondition
        
        Examples:
            | foo |
            |  1  |
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description\nThis is another line.\nThis is a third line."
    end

    @testset "Scenario with blank lines in description; Blank lines in description are included" begin
        text = """
        Scenario Outline: Some description
            This is a longer description

            This is another line.
            This is a third line.

            Given some precondition <foo>

            When some action

            Then some postcondition
        
        Examples:
            | foo |
            |  1  |
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.long_description == "This is a longer description\n\nThis is another line.\nThis is a third line."
    end

    @testset "Long description without steps; Zero steps and a long description" begin
        text = """
        Scenario Outline: Some description
            NotAStep some more text
        
        Examples:
            | foo |
            |  1  |
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)
        @test issuccessful(result)
        scenario = result.value

        @test isempty(scenario.steps)
        @test scenario.long_description == "NotAStep some more text"
    end
end