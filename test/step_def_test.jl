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
end