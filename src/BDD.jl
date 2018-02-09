module BDD

import Base.==

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

abstract type ScenarioStep end
function ==(a::T, b::T) where {T <: ScenarioStep}
    a.text == b.text
end

struct Given <: ScenarioStep
    text::String
end
struct When <: ScenarioStep
    text::String
end
struct Then <: ScenarioStep
    text::String
end

abstract type AbstractScenario end
struct Scenario <: AbstractScenario
    description::String
    tags::Vector{String}
    steps::Vector{ScenarioStep}
end

struct ScenarioOutline <: AbstractScenario end

struct FeatureHeader
    description::String
    long_description::Vector{String}
    tags::Vector{String}
end

struct Feature
    header::FeatureHeader
    scenarios::Vector{AbstractScenario}
end

mutable struct ByLineParser
    current::String
    rest::Vector{String}
    isempty::Bool

    function ByLineParser(text::String)
        lines = split(text, "\n")
        current = lines[1]
        rest = lines[2:end]
        new(current, rest, false)
    end
end

function consume!(p::ByLineParser)
    if isempty(p.rest)
        p.current = ""
        p.isempty = true
    else
        p.current = p.rest[1]
        p.rest = p.rest[2:end]
    end
end

Base.isempty(p::ByLineParser) = p.isempty

iscurrentlineempty(p::ByLineParser) = strip(p.current) == ""

function parsetags(byline::ByLineParser)
    tags = []
    while !isempty(byline)
        tag_match = matchall(r"(@\w+)", byline.current)
        if isempty(tag_match)
            break
        end

        consume!(byline)
        append!(tags, tag_match)
    end

    tags
end

function parsefeatureheader(byline::ByLineParser) :: ParseResult{FeatureHeader}
    feature_tags = parsetags(byline)

    description_match = match(r"Feature: (?<description>.+)", byline.current)
    if description_match == nothing
        return BadParseResult{FeatureHeader}(:unexpected_construct, :feature, :scenario)
    end
    consume!(byline)

    long_description_lines = []
    while !isempty(byline)
        if iscurrentlineempty(byline)
            consume!(byline)
            break
        end

        push!(long_description_lines, strip(byline.current))
        consume!(byline)
    end

    feature_header = FeatureHeader(description_match[:description],
                                   long_description_lines,
                                   feature_tags)
    return OKParseResult{FeatureHeader}(feature_header)
end



function parsescenario(byline::ByLineParser)
    tags = parsetags(byline)

    scenario_match = match(r"Scenario: (?<description>.+)", byline.current)
    scenario_outline_match = match(r"Scenario Outline: (?<description>.+)", byline.current)
    if scenario_outline_match != nothing
        # Parse scenario outline steps
        while !iscurrentlineempty(byline)
            consume!(byline)
        end
        # An empty line is the boundary between the scenario outline and the examples
        consume!(byline)
        # Parse the examples
        while !iscurrentlineempty(byline)
            consume!(byline)
        end
        return OKParseResult{ScenarioOutline}(ScenarioOutline())
    end
    description = scenario_match[:description]
    consume!(byline)
    steps = []
    allowed_step_types = Set([Given, When, Then])

    while !isempty(byline)
        if iscurrentlineempty(byline)
            consume!(byline)
            break
        end
        step_match = match(r"(?<step_type>Given|When|Then|And) (?<step_definition>.+)", byline.current)
        if step_match == nothing
            return BadParseResult{Scenario}(:invalid_step, :step_definition, :invalid_step_definition)
        end
        step_type = step_match[:step_type]
        step_definition = step_match[:step_definition]
        if step_type == "Given"
            if !(Given in allowed_step_types)
                return BadParseResult{Scenario}(:bad_step_order, :NotGiven, :Given)
            end
            step = Given(step_definition)
        elseif step_type == "When"
            if !(When in allowed_step_types)
                return BadParseResult{Scenario}(:bad_step_order, :NotWhen, :When)
            end
            step = When(step_definition)
            delete!(allowed_step_types, Given)
        elseif step_type == "Then"
            step = Then(step_definition)
            delete!(allowed_step_types, Given)
            delete!(allowed_step_types, When)
        elseif step_type == "And"
            if isempty(steps)
                return BadParseResult{Scenario}(:leading_and, :specific_step, :and_step)
            end
            last_specific_type = typeof(steps[end])
            step = last_specific_type(step_definition)
        end
        push!(steps, step)
        consume!(byline)
    end

    OKParseResult{Scenario}(Scenario(description, tags, steps))
end

function parsefeature(text::String) :: ParseResult{Feature}
    byline = ByLineParser(text)

    feature_header_result = parsefeatureheader(byline)
    if !issuccessful(feature_header_result)
        return BadParseResult{Feature}(feature_header_result.reason,
                                       feature_header_result.expected,
                                       feature_header_result.actual)
    end

    scenarios = []
    while !isempty(byline)
        if iscurrentlineempty(byline)
            consume!(byline)
            continue
        end
        scenario_parse_result = parsescenario(byline)
        if issuccessful(scenario_parse_result)
            push!(scenarios, scenario_parse_result.value)
        end
    end

    OKParseResult{Feature}(
        Feature(feature_header_result.value, scenarios))
end

hastag(feature::Feature, tag::String) = tag in feature.header.tags
hastag(scenario::Scenario, tag::String) = tag in scenario.tags

end # module
