module BDD

struct OKParseResult{T}
    value::T
end

issuccessful(::OKParseResult{T}) where {T} = true

struct Scenario
    description::String
end

function parsescenario(text::String) :: OKParseResult{Scenario}
    OKParseResult{Scenario}(Scenario("This is a description"))
end

end # module
