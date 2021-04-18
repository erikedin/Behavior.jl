using Behavior: @given, @when, @then, @expect

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

# This demonstrates the use of a String parameter, which will match
# more than one step.
# NOTE: At the time of writing, only String parameters are supported.
#       In the near future, one will be able to write {Int} directly,
#       and the argument `vstr` will be of type `Int` instead.
@when("foo is set to value {String}") do context, vstr
    v = parse(Int, vstr)
    context[:foo] = v
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