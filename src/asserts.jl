struct StepAssertFailure <: Exception end

macro expect(ex)
    quote
        if !($(esc(ex)))
            throw(StepAssertFailure())
        end
    end
end