using BDD: parsefeature, issuccessful

@testset "Feature" begin
    @testset "Feature description" begin
        @testset "Read feature description; Description matches input" begin
            text = """
            Feature: This is a feature
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test result.value.description == "This is a feature"
        end

        @testset "Read another feature description; Description matches input" begin
            text = """
            Feature: This is another feature
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test result.value.description == "This is another feature"
        end

        @testset "Read long feature description" begin
            text = """
            Feature: This is another feature
              This is the long description.
              It contains several lines.
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test contains(result.value.long_description, "This is the long description.")
            @test contains(result.value.long_description, "It contains several lines")
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
            @test length(result.value.scenarios) == 1        
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
            @test length(result.value.scenarios) == 2
        end

        @testset "Feature has one scenario; The description is read from the scenario" begin
            text = """
            Feature: This feature has one scenario

                Scenario: This is one scenario
                    Given a precondition
            """

            result = parsefeature(text)

            @test issuccessful(result)
            @test result.value.scenarios[1].description == "This is one scenario"
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
            @test result.value.scenarios[1].description == "This is one scenario"
            @test result.value.scenarios[2].description == "This is a second scenario"
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