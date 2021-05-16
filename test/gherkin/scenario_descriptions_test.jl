# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

using Behavior.Gherkin: parsescenario!, issuccessful, Given, When, Then, ByLineParser, ScenarioStep

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

@testset "Outline descriptions " begin
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

    # @testset "Long description without steps; Undefined" begin
    #     # We have problems supporting empty Scenario Outlines because I don't want
    #     # to make "Examples" an unallowed word in scenario descriptions.
    #     # If this turns out to be a problem, we'll have to come up with a solution.
    #     text = """
    #     Scenario Outline: Some description
    #         NotAStep some more text
    #     
    #     Examples:
    #         | foo |
    #         |  1  |
    #     """
    #
    #     byline = ByLineParser(text)
    #     result = parsescenario!(byline)
    # end
end