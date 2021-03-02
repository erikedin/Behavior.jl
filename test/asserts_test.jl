using ExecutableSpecifications
using ExecutableSpecifications.Gherkin

@testset "Asserts              " begin
    @testset "Assert failure; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        try
            @expect 1 == 2
        catch ex
            @test ex.assertion == "1 == 2"
        end
    end

    @testset "Assert failure in included file; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "some precondition" begin
                @expect 1 == 2
            end
        """)
        given = Gherkin.Given("some precondition")
        context = ExecutableSpecifications.StepDefinitionContext()

        m = ExecutableSpecifications.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "1 == 2"
    end

    @testset "Assert failure in included file; Assert is isempty([1]); Failure has human readable string isempty([1])" begin
        matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "some precondition" begin
                @expect isempty([1])
            end
        """)
        given = Gherkin.Given("some precondition")
        context = ExecutableSpecifications.StepDefinitionContext()

        m = ExecutableSpecifications.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "isempty([1])"
    end

    @testset "Fail assertion used in step, Step is StepFailed with assertion 'Some reason'" begin
        matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "some precondition" begin
                @fail "Some reason"
            end
        """)
        given = Gherkin.Given("some precondition")
        context = ExecutableSpecifications.StepDefinitionContext()

        m = ExecutableSpecifications.findstepdefinition(matcher, given)

        args = Dict{Symbol, Any}()
        stepfailed = m.stepdefinition.definition(context, args)

        @test stepfailed.assertion == "Some reason"
    end
end