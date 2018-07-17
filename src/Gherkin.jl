module Gherkin

import Base: ==, hash

export Scenario, ScenarioOutline, Feature, FeatureHeader, Given, When, Then
export parsefeature, hastag

"A good or bad result when parsing Gherkin."
abstract type ParseResult{T} end

"A successful parse that results in the expected value."
struct OKParseResult{T} <: ParseResult{T}
    value::T
end

"An unsuccessful parse that results in an error."
struct BadParseResult{T} <: ParseResult{T}
    reason::Symbol
    expected::Symbol
    actual::Symbol
end

"Was the parsing successful?"
issuccessful(::OKParseResult{T}) where {T} = true
issuccessful(::BadParseResult{T}) where {T} = false

"A step in a Gherkin Scenario."
abstract type ScenarioStep end

"Equality for scenario steps is their text and their block text."
function ==(a::T, b::T) where {T <: ScenarioStep}
    a.text == b.text && a.block_text == b.block_text
end
"Hash scenario steps by their text and block text."
hash(a::T, h::UInt) where {T <: ScenarioStep} = hash((a.text, a.block_text), h)

"A Given scenario step."
struct Given <: ScenarioStep
    text::String
    block_text::String

    Given(text::AbstractString; block_text = "") = new(text, block_text)
end
"A When scenario step."
struct When <: ScenarioStep
    text::String
    block_text::String

    When(text::AbstractString; block_text="") = new(text, block_text)
end
"A Then scenario step."
struct Then <: ScenarioStep
    text::String
    block_text::String

    Then(text::AbstractString; block_text="") = new(text, block_text)
end

"An AbstractScenario is a Scenario or a Scenario Outline in Gherkin."
abstract type AbstractScenario end

"""
A Gherkin Scenario.

# Example
```
@tag1 @tag2
Scenario: Some description
    Given some precondition
     When some action is taken
     Then some postcondition holds
```

becomes a `Scenario` struct with description "Some description", tags `["@tag1", "@tag2"]`, and
steps
```[
    Given("some precondition"),
    When("some action is taken"),
    Then("some postcondition holds")
]```.
"""
struct Scenario <: AbstractScenario
    description::String
    tags::Vector{String}
    steps::Vector{ScenarioStep}
end

"""
A `ScenarioOutline` is a scenario with multiple examples.

# Example
```
@tag1 @tag2
Scenario: Some description
    Given some precondition
     When some action is taken
     Then some postcondition holds
```
"""
struct ScenarioOutline <: AbstractScenario
    description::String
    tags::Vector{String}
    steps::Vector{ScenarioStep}
    placeholders::Vector{String}
    examples::AbstractArray
end

"""
A FeatureHeader has a (short) description, a longer description, and a list of applicable tags.

# Example
```
@tag1 @tag2
Feature: This is a description
    This is
    a longer description.
```
"""
struct FeatureHeader
    description::String
    long_description::Vector{String}
    tags::Vector{String}
end

"""
A Feature has a feature header and a list of Scenarios and Scenario Outlines.
"""
struct Feature
    header::FeatureHeader
    scenarios::Vector{AbstractScenario}
end

"""
ByLineParser takes a long text and lets the Gherkin parser work line by line.
"""
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

"""
    consume!(p::ByLineParser)

The current line has been consumed by the Gherkin parser.
"""
function consume!(p::ByLineParser)
    if isempty(p.rest)
        p.current = ""
        p.isempty = true
    else
        p.current = p.rest[1]
        p.rest = p.rest[2:end]
    end
end

"""
Override the normal `isempty` method for `ByLineParser`.
"""
Base.isempty(p::ByLineParser) = p.isempty

"""
    iscurrentlineempty(p::ByLineParser)

Check if the current line in the parser is empty.
"""
iscurrentlineempty(p::ByLineParser) = strip(p.current) == ""

"""
    parsetags!(byline::ByLineParser)

Parse all tags on form @tagname until a non-tag is encountered. Return a possibly empty list of
tags.
"""
function parsetags!(byline::ByLineParser)
    tags = []
    while !isempty(byline)
        # Use a regular expression to find all occurrences of @tagname on a line.
        tag_match = collect((m.match for m = eachmatch(r"(@[^\s]+)", byline.current)))

        # Break if something that isn't a list of tags is encountered.
        if isempty(tag_match)
            break
        end

        consume!(byline)
        append!(tags, tag_match)
    end

    tags
end

"""
    parsefeatureheader!(byline::ByLineParser) :: ParseResult{FeatureHeader}

Parse a feature header and return the feature header on success, or a bad parse result on failure.

# Example of a feature header
```
@tag1
@tag2
Feature: Some description
    A longer description
    on multiple lines.
```
"""
function parsefeatureheader!(byline::ByLineParser) :: ParseResult{FeatureHeader}
    feature_tags = parsetags!(byline)

    description_match = match(r"Feature: (?<description>.+)", byline.current)
    if description_match == nothing
        return BadParseResult{FeatureHeader}(:unexpected_construct, :feature, :scenario)
    end
    consume!(byline)

    # Consume all lines after the `Feature:` row as a long description, until an empty line is
    # encountered.
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

"""
    parseblocktext!(byline::ByLineParser)

Parse a block of text that may occur as part of a scenario step.
A block of text is multiple lines of text surrounded by three double quotes.
For example, this comment is a valid block text.

Precondition: This function assumes that the current line is the starting line of three double
quotes.
"""
function parseblocktext!(byline::ByLineParser)
    # Consume the current line with three double quotes """
    consume!(byline)
    block_text_lines = []

    # Consume and save all lines, until we reach one that is the ending line of three double quotes.
    while !isempty(byline)
        line = byline.current
        consume!(byline)
        if occursin(r"\"\"\"", line)
            break
        end
        push!(block_text_lines, strip(line))
    end
    return OKParseResult{String}(join(block_text_lines, "\n"))
end

"""
    parsescenariosteps!(byline::ByLineParser)

Parse all scenario steps following a Scenario or Scenario Outline.
"""
function parsescenariosteps!(byline::ByLineParser)
    steps = []
    allowed_step_types = Set([Given, When, Then])

    while !isempty(byline)
        # An empty line indicates the end of the scenario steps.
        if iscurrentlineempty(byline)
            consume!(byline)
            break
        end

        # Match Given, When, or Then on the line, or match a block text.
        # Note: This is a place where English Gherkin is hard coded.
        step_match = match(r"(?<step_type>Given|When|Then|And) (?<step_definition>.+)", byline.current)
        block_text_start_match = match(r"\"\"\"", byline.current)
        # A line must either be a new scenario step, or a block text following the previous scenario
        # step.
        if step_match == nothing && block_text_start_match == nothing
            return BadParseResult{Vector{ScenarioStep}}(:invalid_step, :step_definition, :invalid_step_definition)
        end

        # The current line starts a block text. Parse the rest of the block text and continue with
        # the following line.
        # Note: The method parseblocktext!(byline) consumes the current line, so it doesn't need to
        # be done here.
        if block_text_start_match != nothing
            block_text_result = parseblocktext!(byline)
            prev_step_type = typeof(steps[end])
            steps[end] = prev_step_type(steps[end].text; block_text=block_text_result.value)
            continue
        end

        # The current line is a scenario step.
        # Check that the scenario step is allowed, and create a Given/When/Then object.
        # Note that scenario steps must occur in the order Given, When, Then. A Given may not follow
        # once a When has been seen, and a When must not follow when a Then has been seen.
        # This is what `allowed_step_types` keeps track of.
        step_type = step_match[:step_type]
        step_definition = step_match[:step_definition]
        if step_type == "Given"
            if !(Given in allowed_step_types)
                return BadParseResult{Vector{ScenarioStep}}(:bad_step_order, :NotGiven, :Given)
            end
            step = Given(step_definition)
        elseif step_type == "When"
            if !(When in allowed_step_types)
                return BadParseResult{Vector{ScenarioStep}}(:bad_step_order, :NotWhen, :When)
            end
            step = When(step_definition)
            delete!(allowed_step_types, Given)
        elseif step_type == "Then"
            step = Then(step_definition)
            delete!(allowed_step_types, Given)
            delete!(allowed_step_types, When)
        elseif step_type == "And"
            # A scenario step may be And, in which case it's the same type as the previous step.
            # This means that an And may not be the first scenario step.
            if isempty(steps)
                return BadParseResult{Vector{ScenarioStep}}(:leading_and, :specific_step, :and_step)
            end
            last_specific_type = typeof(steps[end])
            step = last_specific_type(step_definition)
        end
        push!(steps, step)
        consume!(byline)
    end
    return OKParseResult{Vector{ScenarioStep}}(steps)
end

"""
    parsescenario!(byline::ByLineParser)

Parse a Scenario or a Scenario Outline.

# Example of a scenario
```
@tag1 @tag2
Scenario: Some description
    Given some precondition
     When some action is taken
     Then some postcondition holds
```
"""
function parsescenario!(byline::ByLineParser)
    tags = parsetags!(byline)

    # The scenario is either a Scenario or a Scenario Outline. Check for Scenario Outline first.
    scenario_outline_match = match(r"Scenario Outline: (?<description>.+)", byline.current)
    if scenario_outline_match != nothing
        description = scenario_outline_match[:description]
        consume!(byline)

        # Parse scenario outline steps.
        steps_result = parsescenariosteps!(byline)
        if !issuccessful(steps_result)
            return steps_result
        end
        steps = steps_result.value

        # Consume the Example: line.
        consume!(byline)

        # Get the name of each placeholder variable.
        placeholders = collect((m.match for m = eachmatch(r"(\w+)", byline.current)))
        consume!(byline)

        # Parse the examples, until we hit an empty line.
        # TODO: This needs to be updated to allow for multiple Examples sections.
        examples = Array{String,2}(undef, length(placeholders), 0)
        while !iscurrentlineempty(byline)
            # Each variable is in a column, separated by |
            example = split(strip(byline.current), "|")
            filter!(x -> !isempty(x), example)
            # Remove surrounding whitespace around each value.
            example = map(strip, example)
            consume!(byline)
            examples = [examples example]
        end
        return OKParseResult{ScenarioOutline}(
            ScenarioOutline(description, tags, steps, placeholders, examples))
    end

    # Here we parse a normal Scenario instead.
    scenario_match = match(r"Scenario: (?<description>.+)", byline.current)
    description = scenario_match[:description]
    consume!(byline)

    steps_result = parsescenariosteps!(byline)
    if !issuccessful(steps_result)
        return steps_result
    end
    steps = steps_result.value

    OKParseResult{Scenario}(Scenario(description, tags, steps))
end

"""
    parsefeature(::String)

Parse an entire feature file.

# Example of a feature file
```
@tag1 @tag2
Feature: Some feature description
    This is some block text,
    and it may be multiple lines.

    Scenario: Some scenario description
        Given some precondition
         When some action is taken
         Then some postcondition holds
```
"""
function parsefeature(text::String) :: ParseResult{Feature}
    byline = ByLineParser(text)

    # The feature header includes all feature level tags, the description, and the long multiline
    # description.
    feature_header_result = parsefeatureheader!(byline)
    if !issuccessful(feature_header_result)
        return BadParseResult{Feature}(feature_header_result.reason,
                                       feature_header_result.expected,
                                       feature_header_result.actual)
    end

    # Each `parsescenario!`
    scenarios = []
    while !isempty(byline)
        # Just consume all empty lines between scenarios.
        if iscurrentlineempty(byline)
            consume!(byline)
            continue
        end

        scenario_parse_result = parsescenario!(byline)
        if issuccessful(scenario_parse_result)
            push!(scenarios, scenario_parse_result.value)
        end
    end

    OKParseResult{Feature}(
        Feature(feature_header_result.value, scenarios))
end

"""
    hastag(feature::Feature, tag::String)

Check if a feature has a given tag.

# Example
```
feature = parsefeature(featuretext)
hassometag = hastag(feature, "@sometag")
```
"""
hastag(feature::Feature, tag::String) = tag in feature.header.tags
hastag(scenario::Scenario, tag::String) = tag in scenario.tags

end