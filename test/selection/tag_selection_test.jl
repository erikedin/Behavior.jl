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

@testset "New Selection" begin
    #
    # A feature template is created that shows which scenarios are expected
    # to be selected by the tag expression. Each `Yes` scenario is expected
    # to be selected, and each `No` scenario is expected to _not_ be selected.
    # This is all done for readability, so it's clear what each test actually tests.
    #
    # The `FeatureTemplate` struct contains all information needed to create an
    # actual Feature and its Scenarios, to send into the selection method.
    #

    abstract type SelectedOrNot end

    struct Yes <: SelectedOrNot
        tags::Vector{String}
    end

    struct No <: SelectedOrNot
        tags::Vector{String}
    end

    struct FeatureTemplate
        tags::Vector{String}
        selections::Vector{<:SelectedOrNot}
    end

    struct TV
        description::String
        expression::String
        featuretemplate::FeatureTemplate
    end

    function makescenarios(tv::TV)
        AbstractScenario[
            Scenario("Some scenario: $(i)", selectedornot.tags, ScenarioStep[])
            for (i, selectedornot) in enumerate(tv.featuretemplate.selections)
        ]
    end

    function makeyesscenarios(tv::TV)
        AbstractScenario[
            Scenario("Some scenario: $(i)", selectedornot.tags, ScenarioStep[])
            for (i, selectedornot) in enumerate(tv.featuretemplate.selections)
            if isa(selectedornot, Yes)
        ]
    end

    function makefeature(tv::TV)
        scenarios = makescenarios(tv)
        Feature(
            FeatureHeader("Some feature", String[], tv.featuretemplate.tags),
            scenarios)
    end

    testvectors = [
        TV(
            "Expression @foo: Feature has @foo, matches all scenarios",
            "@foo",
            FeatureTemplate(["@foo"],
                [
                    Yes(String[])
                ] 
            )
        )
    ]

    @testset "Scenario equality" begin
        s1 = Scenario("Some scenario", String[], ScenarioStep[])
        s2 = Scenario("Some scenario", String[], ScenarioStep[])
        @test s1 == s2
    end

    for tv in testvectors
        @testset "$(tv.description)" begin
            # Arrange
            feature = makefeature(tv)

            # Act
            selector = newparsetagselector(tv.expression)
            newfeature = select(selector, feature)

            # Assert
            expectedscenarios = makeyesscenarios(tv)
            @test newfeature.scenarios == expectedscenarios
        end
    end
end