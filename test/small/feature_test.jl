using BDD: parsefeature, issuccessful

@testset "Feature         " begin
    @testset "Feature description" begin
        @testset "Read feature description; Description matches input" begin
            text = """
            Feature: This is a feature
            """

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test feature.header.description == "This is a feature"
        end

        @testset "Read another feature description; Description matches input" begin
            text = """
            Feature: This is another feature
            """

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test feature.header.description == "This is another feature"
        end

        @testset "Read long feature description" begin
            text = """
            Feature: This is another feature
              This is the long description.
              It contains several lines.
            """

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test "This is the long description." in feature.header.long_description
            @test "It contains several lines." in feature.header.long_description
        end

        @testset "Scenarios are not part of the feature description" begin
            text = """
            Feature: This is another feature
                This is the long description.
                It contains several lines.

                Scenario: Some scenario
                    Given a precondition
            """

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test ("Given a precondition" in feature.header.long_description) == false
        end
    end

    @testset "Read scenarios" begin
        @testset "Feature has one scenario; one scenarios is parsed" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeature(text)

            @test issuccessful(result)
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

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test length(feature.scenarios) == 2
        end

        @testset "Feature has one scenario; The description is read from the scenario" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeature(text)

            @test issuccessful(result)
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

            result = parsefeature(text)

            @test issuccessful(result)
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

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test length(feature.scenarios[1].steps) == 3
        end

        @testset "Scenario with one step; The parsed scenario has one step" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeature(text)

            @test issuccessful(result)
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

            result = parsefeature(text)

            @test issuccessful(result)
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

            result = parsefeature(text)

            @test issuccessful(result)
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

            result = parsefeature(text)

            @test issuccessful(result)
            feature = result.value
            @test length(feature.scenarios) == 2
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

            result = parsefeature(text)

            @test issuccessful(result) == false
            @test result.reason == :unexpected_construct
            @test result.expected == :feature
            @test result.actual == :scenario
        end
    end
end