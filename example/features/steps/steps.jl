using ExecutableSpecifications: @given, @when, @then, @expect

@given "that the context variable :x has value 1" begin
    context[:x] = 1
end

@when "the context variable :x is compared with 1" begin
    isequal = context[:x] == 1
    context[:result] = isequal
end

@then "the comparison is true" begin
    @expect 1 == 1
end

@when "this step fails" begin
    @expect 1 == 2
end

@then "this step is skipped" begin
    @assert false "This code is never executed, because the previous step failed."
end

@when "this step throws an exception, the result is \"Unknown exception\"" begin
    throw(ErrorException("This is an unknown exception"))
end

# This step is commented to show what happens when a step definition is not found.
#@given "a step that has no corresponding step definition in steps/spec.jl" begin
#
#end

@when "it is executed" begin
    @assert false "This step should be skipped, because the previous failed."
end

@then "it fails with error \"No matching step\"" begin
    @assert false "This step should be skipped, because a previous step failed."
end
