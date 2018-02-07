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

struct FeatureHeader
    description::String
    long_description::Vector{String}
    tags::Vector{String}
end

struct Feature
    header::FeatureHeader
    scenarios::Vector{Scenario}
end

mutable struct ByLineParser
    current::String
    rest::Vector{String}
    isempty::Bool

    function ByLineParser(text::String)
        lines = split(text, "\n")
        if !isempty(lines)
            current = lines[1]
            rest = lines[2:end]
            new(current, rest, false)
        else
            new(current, rest, true)
        end
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
    description = scenario_match[:description]
    consume!(byline)
    steps = []

    while !isempty(byline)
        if iscurrentlineempty(byline)
            consume!(byline)
            return OKParseResult{Scenario}(Scenario(description, tags, steps))
        end
        step = byline.current
        push!(steps, step)
        consume!(byline)
    end

    BadParseResult{Scenario}(:unexpected_end, :scenario_steps, :eof)
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
