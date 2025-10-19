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

@testset "RuleParser           " begin
    @testset "Empty Rule, no description; OK" begin
        # Arrange
        input = ParserInput("""
            Rule:
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == ""
        @test result.value.scenarios == []
    end

    @testset "Empty Rule, Some rule description; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: Some rule description
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == "Some rule description"
        @test result.value.scenarios == []
    end

    @testset "Rule with one scenario; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: Some rule description
                Scenario: Some scenario
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == "Some rule description"
        @test result.value.scenarios[1].description == "Some scenario"
    end

    @testset "Rule with one example; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: Some rule description
                Example: Some scenario
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == "Some rule description"
        @test result.value.scenarios[1].description == "Some scenario"
    end

    @testset "Rule with two scenarios; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: Some rule description
                Scenario: Some scenario
                Scenario: Some other scenario
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == "Some rule description"
        @test result.value.scenarios[1].description == "Some scenario"
        @test result.value.scenarios[2].description == "Some other scenario"
    end

    @testset "Rule with two scenarios any steps; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: Some rule description
                Scenario: Some scenario
                    Given some precondition
                    Given some other precondition
                Scenario: Some other scenario
                    Given some third precondition
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == "Some rule description"
        @test result.value.scenarios[1].description == "Some scenario"
        @test result.value.scenarios[1].steps == [
            Given("some precondition"), Given("some other precondition")
        ]
        @test result.value.scenarios[2].description == "Some other scenario"
        @test result.value.scenarios[2].steps == [
            Given("some third precondition")
        ]
    end

    @testset "Rule with two scenarios any steps separated by blank lines; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: Some rule description

                Scenario: Some scenario
                    Given some precondition
                    Given some other precondition

                Scenario: Some other scenario
                    Given some third precondition
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.description == "Some rule description"
        @test result.value.scenarios[1].description == "Some scenario"
        @test result.value.scenarios[1].steps == [
            Given("some precondition"), Given("some other precondition")
        ]
        @test result.value.scenarios[2].description == "Some other scenario"
        @test result.value.scenarios[2].steps == [
            Given("some third precondition")
        ]
    end

    @testset "Rule; Has a background; Background description is correct" begin
        # Arrange
        input = ParserInput("""
            Rule: With a background
                Background: Rule-specific background
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.background.description == "Rule-specific background"
    end

    @testset "Rule; Background is preceded by a long description; Background description is correct" begin
        # Arrange
        input = ParserInput("""
            Rule: With a background
                This is a long description.

                Background: Rule-specific background
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.background.description == "Rule-specific background"
    end

    @testset "Rule; Background followed by a scenario; Background and scenario description are correct" begin
        # Arrange
        input = ParserInput("""
            Rule: With a background
                Background: Rule-specific background

                Scenario: Some scenario
        """)

        # Act
        parser = RuleParser()
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
        @test result.value.background.description == "Rule-specific background"
        @test result.value.scenarios[1].description == "Some scenario"
    end

    @testset "Rule; One background, then EOF; OK" begin
        # Arrange
        input = ParserInput("""
            Rule: With one Background
                Background: 1
                    Given 1
        """)

        # Act
        parser = RuleParser() >> -eofP
        result = parser(input)

        # Assert
        @test result isa OKParseResult{Rule}
    end

    @testset "Rule; Two backgrounds, then EOF; Not OK" begin
        # Arrange
        input = ParserInput("""
            Rule: With two Backgrounds
                Background: 1
                    Given 1

                Background: 2
                    Given 2
        """)

        # Act
        parser = RuleParser() >> -eofP
        result = parser(input)

        # Assert
        @test result isa BadParseResult{Rule}
    end
end
