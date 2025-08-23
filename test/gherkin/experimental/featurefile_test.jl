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

using Behavior.Gherkin.Experimental: ParserInput, FeatureFileParser, featurefileP

@testset "featurefileP         " begin

@testset "Feature with two scenarios any steps; OK" begin
    # Arrange
    input = ParserInput("""
        Feature: Some feature

            Scenario: Some scenario

            Scenario: Some other scenario
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    @test result.value.header.description == "Some feature"
    @test result.value.scenarios[1].description == "Some scenario"
    @test result.value.scenarios[2].description == "Some other scenario"
end

@testset "Feature, then unallowed new Feature; Not OK" begin
    # Arrange
    input = ParserInput("""
        Feature: Some feature

            Scenario: Some scenario

            Scenario: Some other scenario

            Feature: Not allowed here
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa BadParseResult{Feature}
end

@testset "Feature; Ends with comments; OK" begin
    # Arrange
    input = ParserInput("""
        Feature: Some feature

            Scenario: Some scenario

            # Some comment
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
end

end # FeatureFile