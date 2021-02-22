using Test
using ExecutableSpecifications.Gherkin: Given
using ExecutableSpecifications: FromMacroStepDefinitionMatcher, findstepdefinition

@testset "Variables            " begin
    @testset "Matching against variables; Definition has one variable foo; foo has value bar" begin
        given = Given("some bar")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given "some {foo}" begin end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables[:foo] == "bar"
    end
    
    @testset "Matching against variables; Definition has one variable foo; foo has value baz" begin
        given = Given("some baz")
        stepdef_matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications: @given

            @given "some {foo}" begin end
        """)

        stepdefinitionmatch = findstepdefinition(stepdef_matcher, given)

        @test stepdefinitionmatch.variables[:foo] == "baz"
    end
end