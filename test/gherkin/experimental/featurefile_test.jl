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

using Behavior.Gherkin.Experimental: ParserInput, featurefileP
using Behavior.Gherkin: hastag

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

@testset "featurefileP; Scenario has one tag; The parsed scenario has tag1" begin
    # Arrange
    input = ParserInput("""
    Feature: Some description

        @tag1
        Scenario: Some description
            Given a precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test hastag(feature.scenarios[1], "@tag1")
end

@testset "featurefileP; Feature has tag @tag1; The scenario does not have @tag1" begin
    # Arrange
    input = ParserInput("""
    @tag1
    Feature: Some description

        Scenario: Some description
            Given a precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test !hastag(feature.scenarios[1], "@tag1")
end

@testset "featurefileP; Second scenario has one tag; The second scenario has tag1" begin
    # Arrange
    input = ParserInput("""
    Feature: Some description

        Scenario: No tags here
            Given a precondition

        @tag1
        Scenario: Some description
            Given a precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test hastag(feature.scenarios[2], "@tag1")
end

@testset "featurefileP; Scenario a comment after the tag; The parsed scenario has tag1" begin
    # Arrange
    input = ParserInput("""
    Feature: Some description

        @tag1
        # Some comment
        Scenario: Some description
            Given a precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test hastag(feature.scenarios[1], "@tag1")
end

@testset "featurefileP; Tag has a hypen; The parsed scenario has tag1-a" begin
    # Arrange
    input = ParserInput("""
    Feature: Some description

        @tag1-a
        Scenario: Some description
            Given a precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test hastag(feature.scenarios[1], "@tag1-a")
end

@testset "featurefileP; Scenario has a @ in the description; The description is correctly parsed" begin
    # Arrange
    input = ParserInput("""
    Feature: Some description

        Scenario: Some @tag description
            Given a precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test feature.scenarios[1].description == "Some @tag description"
end

@testset "featurefileP; The last step has a @ ; The step is correctly parsed" begin
    # Arrange
    input = ParserInput("""
    Feature: Some description

        Scenario: Some scenario description
            Given a @tag precondition
    """)

    # Act
    result = featurefileP(input)

    # Assert
    @test result isa OKParseResult{Feature}
    feature = result.value
    @test feature.scenarios[1].steps == [Given("a @tag precondition")]
end
end # FeatureFile