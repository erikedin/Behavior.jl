struct StepAssertFailure <: Exception end

macro expect(ex)
    quote
        if !($ex)
            throw(StepAssertFailure())
        end
    end
end