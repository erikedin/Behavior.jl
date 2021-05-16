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

using Behavior.Gherkin: issuccessful, parsescenario!, Given, When, Then, ByLineParser, ScenarioStep, ParseOptions

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

    @testset "A data table with comments in the elements; Comments are ignored" begin
        text = """
        Scenario: Data tables
            When some action
            Then some tabular data
                | header 1 | header 2 |
                | foo 1    | bar 1    |
                | foo 2    | bar 2    |
                # Comment
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

    @testset "A data table with blank lines; Blank lines are ignored" begin
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

    @testset "The data table step is followed by another step; The data table still has four rows" begin
        text = """
        Scenario: Data tables
            When some action
            Then some tabular data
                | header 1 | header 2 |
                | foo 1    | bar 1    |
                | foo 2    | bar 2    |
                | foo 3    | bar 3    |
             And some other step
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