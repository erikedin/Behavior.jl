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
    tags::Vector{String}
end

function parsefeature(text::String) :: OKParseResult{Feature}
    description_match = match(r"Feature: (.+)", text)

    tag_match = matchall(r"(@\w+)", text)
    feature_tags = if tag_match != nothing
        tag_match
    else
        []
    end

    scenarios = []
    lines = split(text, "\n")
    for l in lines
        scenario_match = match(r"Scenario: (?<description>.+)", l)
        if scenario_match != nothing
            push!(scenarios, Scenario(scenario_match[:description]))
        end
    end

    OKParseResult{Feature}(
        Feature(description_match.captures[1], scenarios, feature_tags))
end

hastag(feature::Feature, tag::String) = tag in feature.tags

end # module
