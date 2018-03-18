using ExecutableSpecifications
using ExecutableSpecifications: findstepdefinition, NonUniqueStepDefinition, StepDefinitionLocation
using ExecutableSpecifications: FromMacroStepDefinitionMatcher, CompositeStepDefinitionMatcher
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications.Gherkin: Given, When, Then

@testset "Step definitions" begin
    @testset "Find a step definition" begin
        @testset "Find a step definition; A matching given step; A step is found" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications.@given

                @given "some definition" begin
                    x = 1
                end
            """)

            stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            @test isa(stepdefinition.definition, Function)
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
            @test isa(stepdefinition.definition, Function)
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
    end

    @testset "Execute a step definition" begin
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
            stepdefinition.definition(context)

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
            stepdefinition.definition(context)

            @test context[:x] == "Some string"
        end

        @testset "Execute a step definition; Retrieve a value from the context; Context value is present" begin
            given = ExecutableSpecifications.Gherkin.Then(":x has value 1")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @then, @expect

                @then ":x has value 1" begin
                    @expect context[:x] == 1
                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            context[:x] = 1
            stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)

            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
        end

        @testset "Execute a step definition; An empty step definition; Success is returned" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications.@given

                @given "some definition" begin

                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
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
            @test stepdefinition.definition(context) == ExecutableSpecifications.StepFailed()
        end

        @testset "Execute a step definition; An assert fails; StepFailed is returned" begin
            when = When("some action")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @when

                @when "some action" begin

                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, when)
            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
        end

        @testset "Execute a step definition; An assert fails; StepFailed is returned" begin
            then = Then("some postcondition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @then

                @then "some postcondition" begin

                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepdefinition = ExecutableSpecifications.findstepdefinition(stepdef_matcher, then)
            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
        end

        @testset "Execute a step definition; Step throws an exception; The error is not caught" begin
            given = Given("some precondition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin
                    throw(ErrorException("Some error"))
                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepdefinition = findstepdefinition(stepdef_matcher, given)
            @test_throws ErrorException stepdefinition.definition(context)
        end
    end

    @testset "Non-unique step definitions" begin
        @testset "Find a step definition; Two step definitions have the same description; NonUniqueStepDefinition is thrown" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications.@given

                @given "some definition" begin
                end

                @given "some definition" begin
                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            @test_throws NonUniqueStepDefinition ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        end

        @testset "Find a step definition; Two step definitions have the same description; File is reported for both" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications.@given

                @given "some definition" begin
                end

                @given "some definition" begin
                end
            """; filename="steps.jl")

            context = ExecutableSpecifications.StepDefinitionContext()
            exception_thrown = false
            try
                ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            catch ex
                if ex isa NonUniqueStepDefinition
                    exception_thrown = true
                    @test ex.locations[1].filename == "steps.jl"
                    @test ex.locations[2].filename == "steps.jl"
                else
                    rethrow()
                end
            end

            @assert exception_thrown "No NonUniqueStepDefinition exception was thrown!"
        end

        @testset "Find a step definition; Two step definitions have the same description; Another file is reported for both" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications.@given


                @given "some definition" begin
                end


                @given "some definition" begin
                end
            """; filename="othersteps.jl")

            context = ExecutableSpecifications.StepDefinitionContext()
            exception_thrown = false
            try
                ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            catch ex
                if ex isa NonUniqueStepDefinition
                    exception_thrown = true
                    @test ex.locations[1].filename == "othersteps.jl"
                    @test ex.locations[2].filename == "othersteps.jl"
                else
                    rethrow()
                end
            end

            @assert exception_thrown "No NonUniqueStepDefinition exception was thrown!"
        end
    end

    @testset "Composite matcher" begin
        @testset "Find a step definition from a composite; First matcher has the definition; Definition is found" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end
            """)

            compositematcher = CompositeStepDefinitionMatcher(matcher1)

            stepdefinition = findstepdefinition(compositematcher, given)
            @test stepdefinition.definition isa Function
            @test stepdefinition.description == "some precondition"
        end

        @testset "Find a step definition from a composite; Second matcher has the definition; Definition is found" begin
            given = Given("some other precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given
            """)
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some other precondition" begin

                end
            """)

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2)

            stepdefinition = findstepdefinition(compositematcher, given)
            @test stepdefinition.definition isa Function
            @test stepdefinition.description == "some other precondition"
        end

        @testset "Find two step definitions from a composite; Both exist in a matcher; Definitions are found" begin
            given = Given("some other precondition")
            when = When("some action")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given


            """)
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some other precondition" begin

                end
            """)
            matcher3 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @when

                @when "some action" begin

                end
            """)

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2, matcher3)

            stepdefinition = findstepdefinition(compositematcher, given)
            @test stepdefinition.definition isa Function
            @test stepdefinition.description == "some other precondition"

            stepdefinition = findstepdefinition(compositematcher, when)
            @test stepdefinition.description == "some action"
        end
    end
end