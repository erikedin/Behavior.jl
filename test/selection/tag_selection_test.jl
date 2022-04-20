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
using Behavior.Selection
using Behavior.Gherkin
using Behavior.Gherkin: AbstractScenario

@testset "Selection            " begin
    # These tests check that the tag selector is parsed and that the expressions are used
    # properly. It uses only tags on scenarios to check this, for simplicity. Tests in a
    # section below check that tags are inherited properly between features and scenarios.
    @testset "Tag selector" begin
        @testset "Feature has tag @foo and no scenarios; Selecting @foo returns no scenarios" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @foo and one scenario; selecting @foo returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags and no scenarios; select @foo returns no scenarios" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], String[])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @bar; Select for @foo returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @foo; Select for @bar returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@bar")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tags @bar and @foo; Select for @foo returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar", "@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags; Selector is (not @foo); select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has tag @foo; Selector is (not @foo); select returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @foo")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @foo; Empty selector; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags; Empty selector; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has no tags; Selector is only whitespace; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("   ")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has tag @baz; Selector is only whitespace; Select returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("   ")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end
    end

    # These tests check that tags are inherited properly between features and scenarios.
    # It assumes that the parsing of tag selectors works as intended, tested above.
    @testset "Feature and Scenario selection" begin
        @testset "Feature has tag @foo and one scenario, no tags; select returns the feature with one scenario" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[])
            ])

            # Act
            selector = parsetagselector("@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Only one scenario has tag @bar; select returns the feature with only that scenario" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String["@bar"], ScenarioStep[]),
                Scenario("Some other scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@bar")
            newfeature = select(selector, feature)

            # Assert
            @test length(newfeature.scenarios) == 1
            @test newfeature.scenarios[1] == feature.scenarios[1]
        end

        @testset "One scenario has tag @ignore; selecting on (not @ignore) returns only the feature without that tag" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], [])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String["@ignore"], ScenarioStep[]),
                Scenario("Some other scenario", String["@other"], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @ignore")
            newfeature = select(selector, feature)

            # Assert
            @test length(newfeature.scenarios) == 1
            @test newfeature.scenarios[1] == feature.scenarios[2]
        end
    end

    @testset "Or expressions" begin
        @testset "Feature has tags @foo and one scenario; selecting @foo,@bar returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@foo,@bar")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has tags @foo and one scenario; selecting @bar,@foo returns the feature unchanged" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("@bar,@foo")
            newfeature = select(selector, feature)

            # Assert
            @test newfeature.scenarios == feature.scenarios
        end

        @testset "Feature has tag @foo; Selector is (not @foo,@bar); select returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@foo"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @foo,@bar")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end

        @testset "Feature has tag @bar; Selector is (not @foo,@bar); select returns nothing" begin
            # Arrange
            header = FeatureHeader("Some feature", String[], ["@bar"])
            feature = Feature(header, AbstractScenario[
                Scenario("Some scenario", String[], ScenarioStep[]),
            ])

            # Act
            selector = parsetagselector("not @foo,@bar")
            newfeature = select(selector, feature)

            # Assert
            @test isempty(newfeature.scenarios)
        end
    end
end

@testset "New Selection        " begin
    struct TV
        description::String
        gherkin::String
        expression::String
        expectedscenariodescriptions::Vector{String}
    end

    # These are the types of expressions, and combinations of expressions, that
    # we'd like to test.
    # - [x] Single tags. Example: Expression @foo matches a feature that has tag @foo
    # - [x] Not expressions. Example: Expression "not @foo" matches a feature that has tag @bar
    # - [x] Or expressions: @foo or @bar
    # - [x] Parentheses expressions: (@foo)
    # - [ ] And expressions: @foo and @bar
    # - [x] An empty tag expression
    #
    # Combinations of the above:
    # - [x] Parentheses with single tags: (@foo)
    # - [ ] Parentheses with or expression inside: (@foo or @bar)
    # - [ ] Parentheses with and expression inside: (@foo and @bar)
    # - [ ] Parentheses with or expression inside, and and outside: (@foo or @bar) and @baz
    # - [ ] Parentheses with or expression inside, and and outside: @baz and (@foo or @bar)
    # - [ ] Parentheses with and expression inside: (@foo and @bar)
    # - [ ] Parentheses with and expression inside, or outside: (@foo and @bar) or @baz
    # - [ ] Parentheses with and expression inside, or outside: @baz or (@foo and @bar)
    # - [ ] Disallow multiple chained expressions without parentheses, due to missing priority
    #       Example: @foo and @bar or @baz, must be one of:
    #                - (@foo and @bar) or @baz
    #                - @foo and (@bar or @baz)
    #       This can be implemented by only making parentheses optional at the first level

    testvectors = [
        #
        # Single tag expression, match features
        #

        TV(
            "Expression @foo will match all scenarios in this feature",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario
                    Give some step
            """,

            "@foo", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario",
            ]
        ),

        TV(
            "Expression @bar will match no scenarios in this feature",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario
                    Give some step
            """,

            "@bar", # Tag selection expression

            # Expression matches these scenarios
            []
        ),

        #
        # Not tag expression, match features
        #

        TV(
            "Expression (not @foo) will match no scenarios in this feature",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario
                    Give some step
            """,

            "not @foo", # Tag selection expression

            # Expression matches these scenarios
            []
        ),

        TV(
            "Expression (not @bar) will match all scenarios in this feature",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario
                    Give some step
            """,

            "not @bar", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario",
            ]
        ),

        #
        # Or expression, tags at feature level
        #

        TV(
            "Expression (@foo or @bar) will match all scenarios in this feature",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "@foo or @bar", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario, or expression",
            ]
        ),

        TV(
            "Expression (@foo or @bar) will match all scenarios in this feature",

            """
            @bar
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "@foo or @bar", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario, or expression",
            ]
        ),

        TV(
            "Expression (@foo or @bar) will not match the feature tag @quux",

            """
            @quux
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "@foo or @bar", # Tag selection expression

            # Expression matches these scenarios
            [
            ]
        ),

        TV(
            "Expression (@foo or @bar) will not match a feature without tags",

            """
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "@foo or @bar", # Tag selection expression

            # Expression matches these scenarios
            [
            ]
        ),

        #
        # Parentheses expression, tags at feature level
        #

        TV(
            "Expression (@foo) will match a feature with tag @foo",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "(@foo)", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario, or expression",
            ]
        ),

        TV(
            "Expression (@foo) will not match a feature with tag @bar",

            """
            @bar
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "(@foo)", # Tag selection expression

            # Expression matches these scenarios
            [
            ]
        ),

        #
        # Empty tag expressions
        #

        TV(
            "An empty expression will match a feature with tag @foo",

            """
            @foo
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario, or expression",
            ]
        ),

        TV(
            "An empty expression will match a feature without tags",

            """
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            "", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario, or expression",
            ]
        ),

        TV(
            "An expression with only whitespace will match a feature without tags",

            """
            Feature: Some feature

                Scenario: Some scenario, or expression
                    Give some step
            """,

            " ", # Tag selection expression

            # Expression matches these scenarios
            [
                "Some scenario, or expression",
            ]
        ),
    ]

    for tv in testvectors
        @testset "$(tv.description)" begin
            # Arrange
            # Parse the Gherkin file, using the good experimental parser
            parser = FeatureFileParser()
            gherkinsource = ParserInput(tv.gherkin)
            parseresult = parser(gherkinsource)
            # Pre-condition: The parse ought to be successful
            @test isparseok(parseresult)
            feature = parseresult.value

            # Act
            selector = newparsetagselector(tv.expression)
            newfeature = select(selector, feature)

            # Assert
            actualscenariodescriptions = [scenario.description for scenario in newfeature.scenarios]
            @test actualscenariodescriptions == tv.expectedscenariodescriptions
        end
    end
end