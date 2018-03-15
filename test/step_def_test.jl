using BDD
using BDD.Gherkin

@testset "Step Definition Matcher" begin
    @testset "Find a step definition; A matching given step; A step is found" begin
        given = BDD.Gherkin.Given("some definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some definition" begin
                x = 1
            end
        """)

        stepdefinition = BDD.findstepdefinition(stepdef_matcher, given)
        @test isa(stepdefinition, Function)
    end

    @testset "Find a step definition; A non-matching given step; No step definition found" begin
        given = BDD.Gherkin.Given("some other definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some definition" begin
                x = 1
            end
        """)

        @test_throws BDD.NoMatchingStepDefinition BDD.findstepdefinition(stepdef_matcher, given)
    end

    @testset "Find a step definition; A matching given step with another description; A step is found" begin
        given = BDD.Gherkin.Given("some other definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some other definition" begin
                x = 1
            end
        """)

        stepdefinition = BDD.findstepdefinition(stepdef_matcher, given)
        @test isa(stepdefinition, Function)
    end

    @testset "Find a step definition in another matcher; The other matcher has no matching step; No step is found" begin
        # This test ensures that step definitions are local to a single matcher, so that they aren't
        # kept globally.
        given = BDD.Gherkin.Given("some definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some definition" begin
                x = 1
            end
        """)

        # There is no step definitions here, so it should not find any matching definitions.
        empty_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given
        """)

        @test_throws BDD.NoMatchingStepDefinition BDD.findstepdefinition(empty_matcher, given)
    end

    @testset "Execute a step definition; Store an int in context; Context stores the value" begin
        given = BDD.Gherkin.Given("some definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some definition" begin
                context[:x] = 1
            end
        """)

        context = BDD.StepDefinitionContext()
        stepdefinition = BDD.findstepdefinition(stepdef_matcher, given)
        stepdefinition(context)

        @test context[:x] == 1
    end

    @testset "Execute a step definition; Store a string in context; Context stores the value" begin
        given = BDD.Gherkin.Given("some definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some definition" begin
                context[:x] = "Some string"
            end
        """)

        context = BDD.StepDefinitionContext()
        stepdefinition = BDD.findstepdefinition(stepdef_matcher, given)
        stepdefinition(context)

        @test context[:x] == "Some string"
    end

    @testset "Execute a step definition; An empty step definition; Success is returned" begin
        given = BDD.Gherkin.Given("some definition")
        stepdef_matcher = BDD.FromMacroStepDefinitionMatcher("""
            using BDD.@given

            @given "some definition" begin
                context[:x] = "Some string"
            end
        """)

        context = BDD.StepDefinitionContext()
        stepdefinition = BDD.findstepdefinition(stepdef_matcher, given)
        @test stepdefinition(context) == BDD.SuccessfulStepExecution()
    end
end