using ExecutableSpecifications
using ExecutableSpecifications.Gherkin

@testset "Step Definition Matcher" begin
    @testset "Find a step definition; A matching given step; A step is found" begin
        given = ExecutableSpecifications.Gherkin.Given("some definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some definition" begin
                x = 1
            end
        """)

        stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        @test isa(stepdefinition, Function)
    end

    @testset "Find a step definition; A non-matching given step; No step definition found" begin
        given = ExecutableSpecifications.Gherkin.Given("some other definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some definition" begin
                x = 1
            end
        """)

        @test_throws ExecutableSpecifications.NoMatchingStepDefinition ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
    end

    @testset "Find a step definition; A matching given step with another description; A step is found" begin
        given = ExecutableSpecifications.Gherkin.Given("some other definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some other definition" begin
                x = 1
            end
        """)

        stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        @test isa(stepdefinition, Function)
    end

    @testset "Find a step definition in another matcher; The other matcher has no matching step; No step is found" begin
        # This test ensures that step definitions are local to a single matcher, so that they aren't
        # kept globally.
        given = ExecutableSpecifications.Gherkin.Given("some definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some definition" begin
                x = 1
            end
        """)

        # There is no step definitions here, so it should not find any matching definitions.
        empty_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given
        """)

        @test_throws ExecutableSpecifications.NoMatchingStepDefinition ExecutableSpecifications.findstepdefinition(empty_matcher, given)
    end

    @testset "Execute a step definition; Store an int in context; Context stores the value" begin
        given = ExecutableSpecifications.Gherkin.Given("some definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some definition" begin
                context[:x] = 1
            end
        """)

        context = ExecutableSpecifications.StepDefinitionContext()
        stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        stepdefinition(context)

        @test context[:x] == 1
    end

    @testset "Execute a step definition; Store a string in context; Context stores the value" begin
        given = ExecutableSpecifications.Gherkin.Given("some definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some definition" begin
                context[:x] = "Some string"
            end
        """)

        context = ExecutableSpecifications.StepDefinitionContext()
        stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        stepdefinition(context)

        @test context[:x] == "Some string"
    end

    @testset "Execute a step definition; An empty step definition; Success is returned" begin
        given = ExecutableSpecifications.Gherkin.Given("some definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications.@given

            @given "some definition" begin
                context[:x] = "Some string"
            end
        """)

        context = ExecutableSpecifications.StepDefinitionContext()
        stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        @test stepdefinition(context) == ExecutableSpecifications.SuccessfulStepExecution()
    end

    @testset "Execute a step definition; An assert fails; StepFailed is returned" begin
        given = ExecutableSpecifications.Gherkin.Given("some definition")
        stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given, @expect

            @given "some definition" begin
                @expect 1 == 2
            end
        """)

        context = ExecutableSpecifications.StepDefinitionContext()
        stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        @test stepdefinition(context) == ExecutableSpecifications.StepFailed()
    end
end