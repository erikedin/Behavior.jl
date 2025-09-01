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

@testset "Block text           " begin

@testset "Scenario; Block text uses ` as delimiter; Block text is read as expected" begin
    # Arrange
    input = ParserInput("""
        Scenario: Some new description
            Given some precondition
                ```
                Block text line.
                ```
    """)

    # Act
    parser = scenarioP >> -eofP
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Scenario}
    scenario = result.value
    # Expecting a single step in that scenario
    given = only(scenario.steps)
    @test given.block_text == "Block text line."
end


end # Block text
