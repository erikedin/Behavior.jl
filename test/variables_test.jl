using Test
using ExecutableSpecifications.Gherkin: Given, When
using ExecutableSpecifications: FromMacroStepDefinitionMatcher, findstepdefinition

@testset "Parameters           " begin
    @testset "Matching against parameters; Definition has one String parameter; has value bar" begin
        given = Given("some bar")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {String}") do context, v end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["bar"]
    end
    
    @testset "Matching against parameters; Definition has one empty String parameter; has value bar" begin
        given = Given("some bar")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {}") do context, v end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["bar"]
    end

    @testset "Matching against parameters; Definition has one String parameter; has value baz" begin
        given = Given("some baz")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {String}") do context, v end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["baz"]
    end

    @testset "Matching against parameters; Definition has two String parameters;  has values bar and fnord" begin
        given = Given("some bar and fnord")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {String} and {String}") do context, v1, v2 end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables == ["bar", "fnord"]
    end

    @testset "Scenario step has a variable foo; Args has :foo => bar" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some value {String}") do context, v
                @expect v == "bar"
            end
        """)
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        given = Given("some value bar")
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Scenario step has two String parameters; Arguments are bar, fnord" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some values {} and {}") do context, v1, v2
                @expect v1 == "bar"
                @expect v2 == "fnord"
            end
        """)
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        given = Given("some values bar and fnord")
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end
end