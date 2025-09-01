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

using Behavior.Gherkin.Experimental: eofP, scenarioP
using Behavior.Gherkin.Experimental: featurefileP, ParserInput, OKParseResult

@testset "Scenario Example     " begin

@testset "Example; Scenario with the Example keyword; Scenario has 1 step" begin
    # Arrange
    input = ParserInput("""
        Example: Some new description
            Given some precondition
    """)

    # Act
    parser = scenarioP >> -eofP
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Scenario}
    scenario = result.value
    @test scenario.description == "Some new description"
    # Expecting a single step in that scenario
    given = only(scenario.steps)
    @test given == Given("some precondition")
end

@testset "Example; Example instead of Scenario; Scenario description is OK" begin
    text = """
    Feature: This feature has one example

        Example: This is one example
            Given a precondition
    """

    input = ParserInput(text)
    result = featurefileP(input)

    @test result isa OKParseResult{Feature}
    feature = result.value
    scenario = only(feature.scenarios)
    @test scenario.description == "This is one example"
end

end # Block text
