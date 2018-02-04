module BDD

struct OKParseResult{T}
    value::T
end

issuccessful(::OKParseResult{T}) where {T} = true

struct Scenario
    description::String
end

function parsescenario(text::String) :: OKParseResult{Scenario}
    lines = split(text, "\n")
    description_match = match(r"Scenario: (.+)", lines[1])
    OKParseResult{Scenario}(Scenario(description_match.captures[1]))
end

end # module
