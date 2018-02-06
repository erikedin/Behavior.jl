module BDD

abstract type ParseResult{T} end

struct OKParseResult{T} <: ParseResult{T}
    value::T
end

struct BadParseResult{T} <: ParseResult{T}
    reason::Symbol
    expected::Symbol
    actual::Symbol
end

issuccessful(::OKParseResult{T}) where {T} = true
issuccessful(::BadParseResult{T}) where {T} = false

struct Scenario
    description::String
    tags::Vector{String}
    steps::Vector{String}
end

struct Feature
    description::String
    long_description::String
    scenarios::Vector{Scenario}
    tags::Vector{String}
end

mutable struct TagState
    tags::Vector{String}

    TagState() = new([])
end

function taketags!(state::TagState)
    tmp = state.tags
    state.tags = []
    tmp
end

function pushtags!(state::TagState, tags::Vector{SubString{String}})
    append!(state.tags, tags)
end

function parsefeature(text::String) :: ParseResult{Feature}
    feature_description = ""
    feature_tags = []

    scenarios = []
    lines = split(text, "\n")
    scenario_description = ""
    scenario_tags = []
    scenario_steps = []
    tagstate = TagState()
    long_description = ""
    for l in lines
        tag_match = matchall(r"(@\w+)", l)
        if !isempty(tag_match)
            pushtags!(tagstate, tag_match)
        end

        description_match = match(r"Feature: (?<feature_description>.+)", l)
        if description_match != nothing
            feature_description = description_match[:feature_description]
            feature_tags = taketags!(tagstate)
        end

        scenario_match = match(r"Scenario: (?<description>.+)", l)
        if scenario_match != nothing
            if feature_description == ""
                return BadParseResult{Feature}(:unexpected_construct, :feature, :scenario)
            end

            scenario_tags = taketags!(tagstate)
            scenario_description = scenario_match[:description]
        end

        if isempty(tag_match) && description_match == nothing && scenario_match == nothing
            if scenario_description == ""
                long_description = string(long_description, "\n", l)
            elseif strip(l) == ""
                scenario = Scenario(scenario_description, scenario_tags, scenario_steps)
                push!(scenarios, scenario)
                scenario_description = ""
            else
                push!(scenario_steps, l)
            end
        end
    end
    if scenario_description != ""
        scenario = Scenario(scenario_description, scenario_tags, scenario_steps)
        push!(scenarios, scenario)
    end

    OKParseResult{Feature}(
        Feature(feature_description, long_description, scenarios, feature_tags))
end

hastag(feature::Feature, tag::String) = tag in feature.tags
hastag(scenario::Scenario, tag::String) = tag in scenario.tags

end # module
