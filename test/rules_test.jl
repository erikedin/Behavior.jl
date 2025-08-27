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

using Test
using Behavior
using Behavior.Gherkin
using Behavior.Gherkin.Experimental
using Behavior: transformoutline

@testset "Rule                 " begin
@testset "Rule; One rule with one scenario; OK" begin
    # Arrange
    engine = ExecutorEngine(QuietRealTimePresenter())
    matcher = FromMacroStepDefinitionMatcher("""
        using Behavior

        @given("value {Int}") do context, v
        end
    """)
    addmatcher!(engine, matcher)

    source = ParserInput("""
        Feature: Scenario Outline with new parser

            Rule: This is a collection of scenarios

                Scenario:
                    Given value 42
    """)
    parser = featurefileP
    parseresult = parser(source)
    feature = parseresult.value

    # Act and Assert
    # The test passes if executing the scenario does not
    # throw an exception.
    runfeature!(engine, feature; keepgoing=true)
end

@testset "Rule; One rule with two scenarios; There are two OK results" begin
    # Arrange
    engine = ExecutorEngine(QuietRealTimePresenter())
    matcher = FromMacroStepDefinitionMatcher("""
        using Behavior

        @given("value {Int}") do context, v
        end
    """)
    addmatcher!(engine, matcher)

    source = ParserInput("""
        Feature: Scenario Outline with new parser

            Rule: This is a collection of scenarios

                Scenario: Some value
                    Given value 42

                Scenario: Another value
                    Given value 17
    """)
    parser = featurefileP
    parseresult = parser(source)
    feature = parseresult.value

    # Act and Assert
    # The test passes if executing the scenario does not
    # throw an exception.
    runfeature!(engine, feature; keepgoing=true)
    result = engine.accumulator
    # There's only one feature here
    feature = only(result.features)
    @test feature.n_success == 2
end

@testset "Rule; 1 good, 1 bad scenario; 1 success, 1 failure" begin
    # Arrange
    engine = ExecutorEngine(QuietRealTimePresenter())
    matcher = FromMacroStepDefinitionMatcher("""
        using Behavior

        @given("value {Int}") do context, v
        end

        @when("a bad action") do context, v
            @expect 1 == 2
        end
    """)
    addmatcher!(engine, matcher)

    source = ParserInput("""
        Feature: Scenario Outline with new parser

            Rule: This is a collection of scenarios

                Scenario: Some value
                    Given value 42

                Scenario: Another value
                    Given value 17
                     When a bad action
    """)
    parser = featurefileP
    parseresult = parser(source)
    feature = parseresult.value

    # Act and Assert
    # The test passes if executing the scenario does not
    # throw an exception.
    runfeature!(engine, feature; keepgoing=true)
    result = engine.accumulator
    # There's only one feature here
    feature = only(result.features)
    @test feature.n_success == 1
    @test feature.n_failure == 1
end

@testset "Rule; One scenario outline with two examples ; There are two OK results" begin
    # Arrange
    engine = ExecutorEngine(QuietRealTimePresenter())
    matcher = FromMacroStepDefinitionMatcher("""
        using Behavior

        @given("value {Int}") do context, v
        end
    """)
    addmatcher!(engine, matcher)

    source = ParserInput("""
        Feature: Scenario Outline with new parser

            Rule: This is a collection of scenarios

                Scenario Outline: Some value
                    Given value <v>

                Examples:
                    | v  |
                    | 42 |
                    | 17 |

    """)
    parser = featurefileP
    parseresult = parser(source)
    feature = parseresult.value

    # Act and Assert
    # The test passes if executing the scenario does not
    # throw an exception.
    runfeature!(engine, feature; keepgoing=true)
    result = engine.accumulator
    # There's only one feature here
    feature = only(result.features)
    @test feature.n_success == 2
end

@testset "Rule; One scenario outline with two examples ; 1 OK, 1 bad result" begin
    # Arrange
    engine = ExecutorEngine(QuietRealTimePresenter())
    matcher = FromMacroStepDefinitionMatcher("""
        using Behavior

        @given("value {Int}") do context, v
            @expect v == 42
        end
    """)
    addmatcher!(engine, matcher)

    source = ParserInput("""
        Feature: Scenario Outline with new parser

            Rule: This is a collection of scenarios

                Scenario Outline: Some value
                    Given value <v>

                Examples:
                    | v  |
                    | 42 |
                    | 17 |

    """)
    parser = featurefileP
    parseresult = parser(source)
    feature = parseresult.value

    # Act and Assert
    # The test passes if executing the scenario does not
    # throw an exception.
    runfeature!(engine, feature; keepgoing=true)
    result = engine.accumulator
    # There's only one feature here
    feature = only(result.features)
    @test feature.n_success == 1
    @test feature.n_failure == 1
end

end # Rule