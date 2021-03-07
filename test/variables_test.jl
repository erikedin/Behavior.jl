using Test
using ExecutableSpecifications.Gherkin: Given, When
using ExecutableSpecifications: FromMacroStepDefinitionMatcher, findstepdefinition

@testset "Variables            " begin
    @testset "Matching against variables; Definition has one variable foo; foo has value bar" begin
        given = Given("some bar")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {foo}") do context end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables[:foo] == "bar"
    end
    
    @testset "Matching against variables; Definition has one variable foo; foo has value baz" begin
        given = Given("some baz")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {foo}") do context end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables[:foo] == "baz"
    end

    @testset "Matching against variables; Definition has one variable quux; quux has value fnord" begin
        given = Given("some fnord")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {quux}") do context end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables[:quux] == "fnord"
    end

    @testset "Matching against variables; Definition has vars foo and quux; foo=bar and quux=fnord" begin
        given = Given("some bar and fnord")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some {foo} and {quux}") do context end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables[:foo] == "bar"
        @test stepdefinitionmatch.variables[:quux] == "fnord"
    end

    @testset "Scenario step has a variable foo; Args has :foo => bar" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some value {foo}") do context
                @expect args[:foo] == "bar"
            end
        """)
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        given = Given("some value bar")
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Scenario step has vars foo, quux; Args has :foo => bar, :quux => fnord" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some values {foo} and {quux}") do context
                @expect args[:foo] == "bar"
                @expect args[:quux] == "fnord"
            end
        """)
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        given = Given("some values bar and fnord")
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end

    @testset "Scenario step 2 has no vars; Args does not have :foo => bar, :quux => fnord" begin
        stepdefmatcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given("some values {foo} and {quux}") do context end

            @when("some action") do context
                @expect !haskey(args, :foo)
                @expect !haskey(args, :quux)
            end
        """)
        executor = ExecutableSpecifications.Executor(stepdefmatcher)

        given = Given("some values bar and fnord")
        when = When("some action")
        scenario = Scenario("Description", String[], ScenarioStep[given, when])

        scenarioresult = ExecutableSpecifications.executescenario(executor, Background(), scenario)

        @test isa(scenarioresult.steps[1], ExecutableSpecifications.SuccessfulStepExecution)
    end
end