struct StepAssertFailure <: Exception
    assertion::String
end

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