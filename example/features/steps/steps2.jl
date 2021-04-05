using ExecutableSpecifications: @given, @when, @then, @expect

@given("some precondition which does nothing") do context

end

@when("we perform a no-op step") do context

end

@then("the scenario as a whole succeeds") do context

end

@when("a step has more than one matching step definition") do context

end

@when("a step has more than one matching step definition") do context

end

@when("foo is set to value 42") do context
    context[:foo] = 42
end

@when("foo is set to value -17") do context
    context[:foo] = -17
end

@then("foo is greater than zero") do context
    @expect context[:foo] > 0
end

@then("foo is less than zero") do context
    @expect context[:foo] < 0
end

@when("we need multiple lines of text") do context
    docstring = context[:block_text]
    @expect docstring == """
        This is line 1.
        This is line 2."""
end

@then("we can use doc strings like this") do context
    docstring = context[:block_text]
    @expect docstring == """
        And like
        this."""
end