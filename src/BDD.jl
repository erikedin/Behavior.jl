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

struct Feature
    description::String
    scenarios::Vector{Scenario}
end

function parsefeature(text::String) :: OKParseResult{Feature}
    description_match = match(r"Feature: (.+)", text)

    scenarios = []
    lines = split(text, "\n")
    for l in lines
        if match(r"Scenario: (?<description>.+)", l) != nothing
            push!(scenarios, Scenario(""))
        end
    end

    OKParseResult{Feature}(
        Feature(description_match.captures[1], scenarios))
end

end # module
