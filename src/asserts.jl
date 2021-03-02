"Thrown at @expect failures in step definitions."
struct StepAssertFailure <: Exception
    assertion::String
end

"""
    expect(ex)

Assert that a condition `ex` is true. Throws a StepAssertFailure if false.

# Examples
```
@then "this condition should hold" begin
    @expect 1 == 1
end
```

This will fail and throw a `StepAssertFailure`
```
@then "this condition should not hold" begin
    @expect 1 == 2
end
```
"""
macro expect(ex)
    # Create a human readable form of the expectation.
    if length(ex.args) > 0 && ex.args[1] isa Expr && ex.args[1].head == :globalref
        operator = ex.args[1].args[2]
        readable_ex = copy(ex)
        readable_ex.args[1] = operator
    else
        readable_ex = ex
    end

    quote
        # Check the expectation.
        if !($(esc(ex)))
            throw(StepAssertFailure($(string(readable_ex))))
        end
    end
end

"""
    @fail(message)

Fail a step with a descriptive message.
"""
macro fail(message)
    quote
        throw(StepAssertFailure($message))
    end
end