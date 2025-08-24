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

using Behavior.Gherkin:
    parsefeature, issuccessful, ParseOptions,
    Given, When, Then

using Behavior.Gherkin.Experimental: featurefileP, ParserInput, OKParseResult

function parsefeatureP(text::String)
    input = ParserInput(text)
    featurefileP(input)
end

@testset "Feature              " begin
    @testset "Feature description" begin
        @testset "Read feature description; Description matches input" begin
            text = """
            Feature: This is a feature
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.header.description == "This is a feature"
        end

        @testset "Read another feature description; Description matches input" begin
            text = """
            Feature: This is another feature
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.header.description == "This is another feature"
        end

        @testset "Read long feature description" begin
            text = """
            Feature: This is another feature
              This is the long description.
              It contains several lines.
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            # TODO: The FeatureHeader has a vector of lines as the long_description.
            # This should just be a string, so it needs to be changed. With the new
            # Gherkin parser it is indeed a string, but is encased in a single-element
            # Vector just to get it to work. So, just check that one element instead.
            # When the FeatureHeader is fixed, remove [1] here.
            @test contains(feature.header.long_description[1], "This is the long description.")
            @test contains(feature.header.long_description[1], "It contains several lines.")
        end

        @testset "Scenarios are not part of the feature description" begin
            text = """
            Feature: This is another feature
                This is the long description.
                It contains several lines.

                Scenario: Some scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            # TODO: The FeatureHeader has a vector of lines as the long_description.
            # This should just be a string, so it needs to be changed. With the new
            # Gherkin parser it is indeed a string, but is encased in a single-element
            # Vector just to get it to work. So, just check that one element instead.
            # When the FeatureHeader is fixed, remove [1] here.
            @test !contains(feature.header.long_description[1], "Given a precondition")
        end
    end

    @testset "Read scenarios" begin
        @testset "Feature has one scenario; one scenarios is parsed" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 1
        end

        @testset "Feature has two scenarios; two scenarios are parsed" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition

                Scenario: This is a second scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 2
        end

        @testset "Feature has one scenario; The description is read from the scenario" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.scenarios[1].description == "This is one scenario"
        end

        @testset "Feature has two scenarios; two scenarios are parsed" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition

                Scenario: This is a second scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.scenarios[1].description == "This is one scenario"
            @test feature.scenarios[2].description == "This is a second scenario"
        end

        @testset "Scenario with three steps; The parsed scenario has three steps" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
                    When an action is performed
                    Then some postcondition holds
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios[1].steps) == 3
        end

        @testset "Scenario with one step; The parsed scenario has one step" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios[1].steps) == 1
        end

        @testset "Feature has a scenario outline; The feature scenarios list has one element" begin
            text = """
            Feature: This feature has one scenario

                Scenario Outline: This is one scenario outline
                    Given a precondition with field <Foo>

                Examples:
                    | Foo |
                    | 1   |
                    | 2   |
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 1
        end

        @testset "Feature has a scenario outline and a normal scenario; Two scenarios are parsed" begin
            text = """
            Feature: This feature has one scenario

                Scenario Outline: This is one scenario outline
                    Given a precondition with field <Foo>

                Examples:
                    | Foo |
                    | 1   |
                    | 2   |

                Scenario: A normal scenario
                    Given some precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 2
        end
    end

    @testset "Robustness" begin
        @testset "Many empty lines before scenario; Empty lines are ignored" begin
            text = """
            Feature: This feature has many empty lines between scenarios




                Scenario: This is one scenario
                    Given a precondition



                Scenario: This is another scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 2
        end

        @testset "No empty lines between scenarios; Two scenarios found" begin
            text = """
            Feature: This feature has no empty lines between scenarios

                Scenario: This is one scenario
                    Given a precondition
                Scenario: This is another scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 2
        end

        @testset "No empty lines between a Scenario and a Scenario Outline; Two scenarios found" begin
            text = """
            Feature: This feature has no empty lines between scenarios

                Scenario: This is one scenario
                    Given a precondition
                Scenario Outline: This is one scenario outline
                    Given a precondition with field <Foo>

                Examples:
                    | Foo |
                    | 1   |
                    | 2   |
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 2
        end

        @testset "No empty lines between a Scenario Outline and a Scenario; Two scenarios found" begin
            text = """
            Feature: This feature has no empty lines between scenarios

                Scenario Outline: This is one scenario outline
                    Given a precondition with field <Foo>

                Examples:
                    | Foo |
                    | 1   |
                    | 2   |
                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 2
        end

        @testset "No empty lines between a Scenario Outline and the examples; One scenario found" begin
            text = """
            Feature: This feature has no empty lines between scenarios

                Scenario Outline: This is one scenario outline
                    Given a precondition with field <Foo>
                Examples:
                    | Foo |
                    | 1   |
                    | 2   |
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 1
        end

        @testset "No empty lines between a Feature and a Scenario; Scenario found" begin
            text = """
            Feature: This feature has no empty lines between scenarios
                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 1
        end

        @testset "The feature file has three empty scenarios; The Feature has three scenarios" begin
            text = """
            Feature: This feature has no empty lines between scenarios

                Scenario: This is one scenario

                Scenario: This is another scenario

                Scenario: This is a third scenario
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test length(feature.scenarios) == 3
        end
    end

    @testset "Malformed features" begin
        @testset "Scenario found before feature; Parse fails with feature expected" begin
            text = """
                Scenario: This is one scenario
                    Given a precondition

            Feature: This feature has one scenario

                Scenario: This is a second scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa BadParseResult{Feature}
        end

        @testset "Scenario found before feature; Parser fails on line 1" begin
            text = """
                Scenario: This is one scenario
                    Given a precondition

            Feature: This feature has one scenario

                Scenario: This is a second scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa BadParseResult{Feature}
        end

        @testset "Scenario found before feature; Parser fails on line 1" begin
            text = """
                Scenario: This is one scenario
                    Given a precondition

            Feature: This feature has one scenario

                Scenario: This is a second scenario
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa BadParseResult{Feature}
        end

    end

    @testset "Lenient parser" begin
        @testset "Allow arbitrary step order" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This scenario has steps out-of-order
                    Then a postcondition
                    When an action
                    Given a precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
        end
    end

    @testset "Background sections" begin
        @testset "Background with a single Given step; Background description is available in the result" begin
            text = """
            Feature: This feature has a Background section

                Background: Some background steps
                    Given some background precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.description == "Some background steps"
        end

        @testset "Background with a single Given step; The Given step is available in the result" begin
            text = """
            Feature: This feature has a Background section

                Background: Some background steps
                    Given some background precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.steps == [Given("some background precondition")]
        end

        @testset "Background with three Given steps; The Given steps are available in the result" begin
            text = """
            Feature: This feature has a Background section

                Background: Some background steps
                    Given some background precondition 1
                    Given some background precondition 2
                    Given some background precondition 3
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.steps == [
                Given("some background precondition 1"),
                Given("some background precondition 2"),
                Given("some background precondition 3"),
            ]
        end

        @testset "Background with a doc string; The doc string is part of the step" begin
            text = """
            Feature: This feature has a Background section

                Background: Some background steps
                    Given some background precondition
                        \"\"\"
                        Doc string
                        \"\"\"
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.steps == [
                Given("some background precondition"; block_text="Doc string"),
            ]
        end

        @testset "Background with a When step type; This is allowed" begin
            text = """
            Feature: This feature has a Background section

                Background: Some background steps
                    Given some background precondition
                    When some action
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
        end

        @testset "Background with a Then step type; This is allowed" begin
            text = """
            Feature: This feature has a Background section

                Background: Some background steps
                    Given some background precondition
                    Then some postcondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
        end

        @testset "Background has no description; Description is empty" begin
            text = """
            Feature: This feature has a Background section

                Background:
                    Given some background precondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.description == ""
        end
    end

    @testset "Comments" begin
        @testset "Comments preceding the Feature; Ignored" begin
            text = """
            # Comment line 1
            # Comment line 2
            Feature: This is a feature
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.header.description == "This is a feature"
        end

        @testset "Comments within a Background; Ignored" begin
            text = """
            Feature: This is a feature

                Background: Some description
                    Given some precondition 1
                    # Comment line 1
                    # Comment line 2
                    Given some precondition 2
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.steps == [
                Given("some precondition 1"),
                Given("some precondition 2"),
            ]
        end

        @testset "Comments within a Scenario; Ignored" begin
            text = """
            Feature: This is a feature

                Scenario: Some description
                    Given some precondition 1
                    # Comment line 1
                    # Comment line 2
                    Given some precondition 2
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.scenarios[1].steps == [
                Given("some precondition 1"),
                Given("some precondition 2"),
            ]
        end

        @testset "Comments between a Background and a Scenario; Ignored" begin
            text = """
            Feature: This is a feature

                Background: Some background description
                    Given some background precondition

                # Comment line 1
                # Comment line 2

                Scenario: Some description
                    Given some precondition 1
                    When some action
                    Then some postcondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.steps == [
                Given("some background precondition"),
            ]
            @test feature.scenarios[1].steps == [
                Given("some precondition 1"),
                When("some action"),
                Then("some postcondition"),
            ]
        end

        @testset "Comments between a Background and a Scenario without blank lines; Ignored" begin
            text = """
            Feature: This is a feature

                Background: Some background description
                    Given some background precondition
                # Comment line 1
                # Comment line 2
                Scenario: Some description
                    Given some precondition 1
                    When some action
                    Then some postcondition
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.background.steps == [
                Given("some background precondition"),
            ]
            @test feature.scenarios[1].steps == [
                Given("some precondition 1"),
                When("some action"),
                Then("some postcondition"),
            ]
        end

        @testset "Comments at the end of a Feature; Ignored" begin
            text = """
            Feature: This is a feature

                Scenario: Some description
                    Given some precondition 1
                    When some action
                    Then some postcondition

                # Comment line 1
                # Comment line 2
            """

            result = parsefeatureP(text)

            @test result isa OKParseResult{Feature}
            feature = result.value
            @test feature.scenarios[1].steps == [
                Given("some precondition 1"),
                When("some action"),
                Then("some postcondition"),
            ]
        end
    end
end