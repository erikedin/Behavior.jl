using ExecutableSpecifications: @given, @when, @then, @expect

@given "some precondition which does nothing" begin

end

@when "we perform a no-op step" begin

end

@then "the scenario as a whole succeeds" begin

end

@when "a step has more than one matching step definition" begin

end

@when "a step has more than one matching step definition" begin

end

@when "foo is set to value 42" begin
    context[:foo] = 42
end

@when "foo is set to value -17" begin
    context[:foo] = -17
end

@then "foo is greater than zero" begin
    @expect context[:foo] > 0
end

@then "foo is less than zero" begin
    @expect context[:foo] < 0
end