using ExecutableSpecifications
using ExecutableSpecifications: findstepdefinition, NonUniqueStepDefinition, StepDefinitionLocation, NoMatchingStepDefinition
using ExecutableSpecifications: FromMacroStepDefinitionMatcher, CompositeStepDefinitionMatcher, addmatcher!
using ExecutableSpecifications.Gherkin
using ExecutableSpecifications.Gherkin: Given, When, Then

@testset "Step definitions     " begin
    @testset "Find a step definition" begin
        @testset "Find a step definition; A matching given step; A step is found" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some definition" begin
                    x = 1
                end
            """)

            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test isa(stepdefinition.definition, Function)
        end

        @testset "Find a step definition; A non-matching given step; No step definition found" begin
            given = ExecutableSpecifications.Gherkin.Given("some other definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some definition" begin
                    x = 1
                end
            """)

            @test_throws ExecutableSpecifications.NoMatchingStepDefinition ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
        end

        @testset "Find a step definition; A matching given step with another description; A step is found" begin
            given = ExecutableSpecifications.Gherkin.Given("some other definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some other definition" begin
                    x = 1
                end
            """)

            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test isa(stepdefinition.definition, Function)
        end

        @testset "Find a step definition in another matcher; The other matcher has no matching step; No step is found" begin
            # This test ensures that step definitions are local to a single matcher, so that they aren't
            # kept globally.
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some definition" begin
                    x = 1
                end
            """)

            # There is no step definitions here, so it should not find any matching definitions.
            empty_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given
            """)

            @test_throws ExecutableSpecifications.NoMatchingStepDefinition ExecutableSpecifications.findstepdefinition(empty_matcher, given)
        end
    end

    @testset "Execute a step definition" begin
        @testset "Execute a step definition; Store an int in context; Context stores the value" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some definition" begin
                    context[:x] = 1
                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
            stepdefinition.definition(context)

            @test context[:x] == 1
        end

        @testset "Execute a step definition; Store a string in context; Context stores the value" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some definition" begin
                    context[:x] = "Some string"
                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
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
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition

            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
        end

        @testset "Execute a step definition; An empty step definition; Success is returned" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some definition" begin

                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
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
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.definition(context) isa ExecutableSpecifications.StepFailed
        end

        @testset "Execute a step definition; An empty When step; Success is returned" begin
            when = When("some action")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @when

                @when "some action" begin

                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, when)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
        end

        @testset "Execute a step definition; An empty Then step; Success is returned" begin
            then = Then("some postcondition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @then

                @then "some postcondition" begin

                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, then)
            stepdefinition = stepmatch.stepdefinition
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
            stepmatch = findstepdefinition(stepdef_matcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test_throws ErrorException stepdefinition.definition(context)
        end

        @testset "Execute a step definition; Call a method defined in the steps file; Method is in scope" begin
            when = ExecutableSpecifications.Gherkin.When("calling empty function foo")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @when

                foo() = nothing

                @when "calling empty function foo" begin
                    foo()
                end
            """)

            context = ExecutableSpecifications.StepDefinitionContext()
            stepmatch = ExecutableSpecifications.findstepdefinition(stepdef_matcher, when)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.definition(context) == ExecutableSpecifications.SuccessfulStepExecution()
        end
    end

    @testset "Non-unique step definitions" begin
        @testset "Find a step definition; Two step definitions have the same description; NonUniqueStepDefinition is thrown" begin
            given = ExecutableSpecifications.Gherkin.Given("some definition")
            stepdef_matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

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
                using ExecutableSpecifications: @given

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
                using ExecutableSpecifications: @given


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

            stepmatch = findstepdefinition(compositematcher, given)
            stepdefinition = stepmatch.stepdefinition
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

            stepmatch = findstepdefinition(compositematcher, given)
            stepdefinition = stepmatch.stepdefinition
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

            stepmatch = findstepdefinition(compositematcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.definition isa Function
            @test stepdefinition.description == "some other precondition"

            stepmatch = findstepdefinition(compositematcher, when)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.description == "some action"
        end

        @testset "Find a step definition from a composite; Matching two definitions; Non unique step exception thrown" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end
            """)
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end
            """)

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2)

            @test_throws NonUniqueStepDefinition findstepdefinition(compositematcher, given)
        end

        @testset "Find a step definition from a composite; Matching two definitions in one matcher; Non unique step exception thrown" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end

                @given "some precondition" begin

                end
            """)
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given
            """)

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2)

            @test_throws NonUniqueStepDefinition findstepdefinition(compositematcher, given)
        end

        @testset "Find a step definition from a composite; Matches in both matchers; Non unique locations indicates both matchers" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end
            """; filename="matcher1.jl")
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end
            """; filename="matcher2.jl")

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2)

            exception_is_thrown = false
            try
                findstepdefinition(compositematcher, given)
            catch ex
                if ex isa NonUniqueStepDefinition
                    exception_is_thrown = true
                    location_filenames = [location.filename for location in ex.locations]
                    @test "matcher1.jl" in location_filenames
                    @test "matcher2.jl" in location_filenames
                else
                    rethrow()
                end
            end

            @test exception_is_thrown
        end

        @testset "Find a step definition from a composite; Two matchings in one and one matching in second matcher; Non unique locations indicates both matchers" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end

                @given "some precondition" begin

                end
            """; filename="matcher1.jl")
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some precondition" begin

                end
            """; filename="matcher2.jl")

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2)

            exception_is_thrown = false
            try
                findstepdefinition(compositematcher, given)
            catch ex
                if ex isa NonUniqueStepDefinition
                    exception_is_thrown = true
                    location_filenames = [location.filename for location in ex.locations]
                    @test "matcher1.jl" in location_filenames
                    @test "matcher2.jl" in location_filenames
                else
                    rethrow()
                end
            end

            @test exception_is_thrown
        end

        @testset "Find a step definition from a composite; No matches found; NoMatchingStepDefinition thrown" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given
            """)
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given
            """)

            compositematcher = CompositeStepDefinitionMatcher(matcher1, matcher2)

            @test_throws NoMatchingStepDefinition findstepdefinition(compositematcher, given)
        end

        @testset "Add a matcher after construction; Definition is found" begin
            given = Given("some precondition")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications

                @given "some precondition" begin end
            """)

            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher1)

            stepmatch = findstepdefinition(compositematcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.definition isa Function
            @test stepdefinition.description == "some precondition"
        end

        @testset "Add two step definitions to a composite; Both exist in a matcher; Definitions are found" begin
            given = Given("some other precondition")
            when = When("some action")
            matcher1 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @given

                @given "some other precondition" begin

                end
            """)
            matcher2 = FromMacroStepDefinitionMatcher("""
                using ExecutableSpecifications: @when

                @when "some action" begin

                end
            """)

            compositematcher = CompositeStepDefinitionMatcher()
            addmatcher!(compositematcher, matcher1)
            addmatcher!(compositematcher, matcher2)

            stepmatch = findstepdefinition(compositematcher, given)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.definition isa Function
            @test stepdefinition.description == "some other precondition"

            stepmatch = findstepdefinition(compositematcher, when)
            stepdefinition = stepmatch.stepdefinition
            @test stepdefinition.description == "some action"
        end
    end
end