module Gherkin

import Base: ==, hash

export Scenario, ScenarioOutline, Feature, FeatureHeader, Given, When, Then, ScenarioStep
export parsefeature, hastag, ParseOptions

"A step in a Gherkin Scenario."
abstract type ScenarioStep end

"Equality for scenario steps is their text and their block text."
function ==(a::T, b::T) where {T <: ScenarioStep}
    a.text == b.text && a.block_text == b.block_text
end
"Hash scenario steps by their text and block text."
hash(a::T, h::UInt) where {T <: ScenarioStep} = hash((a.text, a.block_text), h)

const DataTableRow = Vector{String}
const DataTable = Array{DataTableRow, 1}

"A Given scenario step."
struct Given <: ScenarioStep
    text::String
    block_text::String
    datatable::DataTable

    Given(text::AbstractString; block_text = "", datatable=DataTable()) = new(text, block_text, datatable)
end
"A When scenario step."
struct When <: ScenarioStep
    text::String
    block_text::String
    datatable::DataTable

    When(text::AbstractString; block_text="", datatable=DataTable()) = new(text, block_text, datatable)
end
"A Then scenario step."
struct Then <: ScenarioStep
    text::String
    block_text::String
    datatable::DataTable

    Then(text::AbstractString; block_text="", datatable=DataTable()) = new(text, block_text, datatable)
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
    long_description::String

    function Scenario(description::AbstractString, tags::Vector{String}, steps::Vector{ScenarioStep}; long_description::AbstractString = "")
        new(description, tags, steps, long_description)
    end
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
    long_description::String

    function ScenarioOutline(
            description::AbstractString,
            tags::Vector{String},
            steps::Vector{ScenarioStep},
            placeholders::AbstractVector{String},
            examples::AbstractArray;
            long_description::AbstractString = "")
        new(description, tags, steps, placeholders, examples, long_description)
    end
end

struct Background
    description::String
    steps::Vector{ScenarioStep}
end
Background() = Background("", ScenarioStep[])

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
    background::Background
    scenarios::Vector{AbstractScenario}

    Feature(header::FeatureHeader, background::Background, scenarios::Vector{<:AbstractScenario}) = new(header, background, scenarios)
    Feature(header::FeatureHeader, scenarios::Vector{<:AbstractScenario}) = new(header, Background(), scenarios)
end

"""
ParseOptions lets the user control certain behavior of the parser, making it more lenient towards errors.
"""
struct ParseOptions
    allow_any_step_order::Bool

    function ParseOptions(;
        allow_any_step_order::Bool = false)

        new(allow_any_step_order)
    end
end

"""
ByLineParser takes a long text and lets the Gherkin parser work line by line.
"""
mutable struct ByLineParser
    current::String
    rest::Vector{String}
    isempty::Bool
    linenumber::Union{Nothing, Int}
    options::ParseOptions

    function ByLineParser(text::String, options::ParseOptions = ParseOptions())
        lines = split(text, "\n")
        current = lines[1]
        rest = lines[2:end]
        new(current, rest, false, 1, options)
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
        p.linenumber = nothing
    else
        p.current = p.rest[1]
        p.rest = p.rest[2:end]
        p.linenumber += 1
    end
end

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
    linenumber::Union{Nothing, Int}
    line::String

    function BadParseResult{T}(reason::Symbol, expected::Symbol, actual::Symbol, parser::ByLineParser) where {T}
        new(reason, expected, actual, parser.linenumber, parser.current)
    end

    function BadParseResult{T}(reason::Symbol, expected::Symbol, actual::Symbol, linenumber::Int, line::String) where {T}
        new(reason, expected, actual, linenumber, line)
    end
end

function BadParseResult{T}(inner::BadParseResult{K}) where {T, K} 
    BadParseResult{T}(inner.reason, inner.expected, inner.actual, inner.linenumber, inner.line)
end

"Was the parsing successful?"
issuccessful(::OKParseResult{T}) where {T} = true
issuccessful(::BadParseResult{T}) where {T} = false


"""
    lookaheadfor(byline::ByLineParser, istarget::Function, isallowedprefix::Function)

Look ahead to see if all lines match isallowedprefix until we reach a line
matching istarget.

Example: Here the tags mark the start of the scenario
    @tag1
    @tag2
    @tag3
    Scenario: Some scenario

    `lookaheadfor(byline, iscurrentlineasection, istagline) -> true` 

Example: Here the tags _do_ not mark the start of the scenario
    @tag1
    @tag2
    @tag3

    This is some free text.

    Scenario: Some scenario

    `lookaheadfor(byline, iscurrentlineasection, istagline) -> false` 
"""
function lookaheadfor(byline::ByLineParser, istarget::Function, isallowedprefix::Function) :: Bool
    for nextline in byline.rest
        if istarget(nextline)
            return true
        end

        if isallowedprefix(nextline)
            continue
        end

        # The line matched neither istarget or isallowedprefix.
        # Therefore the current line did not mark the beginning of an
        # istarget line.
        break
    end

    false
end

"""
    @untilemptyline(byline::Symbol,)

Execute the function for each line, until an empty line is encountered, or no further lines are
available.
"""
macro untilemptyline(ex::Expr)
    esc(quote
        while !isempty(byline)
            if iscurrentlineempty(byline)
                consume!(byline)
                break
            end
            $ex
            consume!(byline)
        end
    end)
end

function iscurrentlineasection(s::String)
    m = match(r"(Background|Scenario|Scenario Outline|Examples):.*", s)
    m !== nothing
end

iscomment(s::AbstractString) = startswith(strip(s), "#")

"""
    @untilnextsection(byline::Symbol,)

Execute the function for each line, until another section is encountered, or no further lines are
available.
A section is another Scenario, Scenario Outline.
Also skips empty lines and comment lines.
"""
macro untilnextsection(ex::Expr)
    esc(quote
        while !isempty(byline)
            if iscurrentlineasection(byline.current)
                break
            end
            if istagsline(byline.current) && lookaheadfor(byline, iscurrentlineasection, x -> istagsline(x) || iscomment(x))
                break
            end
            if iscurrentlineempty(byline)
                consume!(byline)
                continue
            end
            $ex
            consume!(byline)
        end
    end)
end

isstoppingline(pattern::Regex, s::AbstractString) = match(pattern, s) !== nothing

"""
    @untilnextstep(byline::Symbol, steps = "Given|When|Then|And|But")

Execute the function for each line, until a step is encountered, or no further lines are
available.
Also skips empty lines and comment lines.
"""
macro untilnextstep(ex::Expr, steps = ["Given", "When", "Then", "And", "But"])
    esc(quote
        stepsregex = join($steps, "|")
        regex = "^($(stepsregex))"
        r = Regex(regex)

        while !isempty(byline)
            if isstoppingline(r, strip(byline.current))
                break
            end
            $ex
            consume!(byline)
        end
    end)
end

"""
    ignoringemptylines!(f::Function, byline::ByLineParser)

Execute function `f` for all non-empty lines, until the end of the file.
"""
macro ignoringemptylines(ex::Expr)
    esc(quote
        while !isempty(byline)
            if iscurrentlineempty(byline)
                consume!(byline)
                continue
            end

            $ex
        end
    end)
end

"""
Override the normal `isempty` method for `ByLineParser`.
"""
Base.isempty(p::ByLineParser) = p.isempty

"""
    iscurrentlineempty(p::ByLineParser)

Check if the current line in the parser is empty.
"""
iscurrentlineempty(p::ByLineParser) = strip(p.current) == "" || startswith(strip(p.current), "#")

function consumeemptylines!(p::ByLineParser)
    while !isempty(p) && iscurrentlineempty(p)
        consume!(p)
    end
end


"""
    istagsline(current::String)

True if this is a line containing only tags, false otherwise.
"""
function istagsline(current::String)
    tagsandwhitespace = split(current, r"\s+")
    thesetags = filter(x -> !isempty(x), tagsandwhitespace)
    # the all function will match an empty list, which would happen on blank lines,
    # so we have to manually check for an empty list.
    !isempty(thesetags) && all(startswith("@"), thesetags)
end

"""
    parsetags!(byline::ByLineParser)

Parse all tags on form @tagname until a non-tag is encountered. Return a possibly empty list of
tags.
"""
function parsetags!(byline::ByLineParser) :: Vector{String}
    tags = String[]
    while !isempty(byline)
        if iscomment(byline.current)
            consume!(byline)
            continue
        end
        tagsandwhitespace = split(byline.current, r"\s+")
        thesetags = filter(x -> !isempty(x), tagsandwhitespace)
        istags = all(startswith("@"), thesetags)
        # Break if something that isn't a list of tags is encountered.
        if !istags
            break
        end

        consume!(byline)
        append!(tags, thesetags)
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
        return BadParseResult{FeatureHeader}(:unexpected_construct, :feature, :scenario, byline)
    end
    consume!(byline)

    # Consume all lines after the `Feature:` row as a long description, until a keyword is
    # encountered.
    long_description_lines = []
    @untilnextsection begin
        push!(long_description_lines, strip(byline.current))
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
    @untilnextstep begin
        line = byline.current
        push!(block_text_lines, strip(line))
    end ["\"\"\""]
    consume!(byline)
    return OKParseResult{String}(join(block_text_lines, "\n"))
end

"""
    parsetable!(byline::ByLineParser)

Parse a table delimited by |.

# Example
```Gherkin
Scenario: Table
    Given a data table
        | header 1 | header 2 |
        | foo      | bar      |
        | baz      | quux     |
```

If `parsetable!` is called on the line containing the headers,
then all lines of the table will be returned.
"""
function parsetable!(byline::ByLineParser) :: ParseResult{DataTable}
    table = DataTable()

    @untilnextsection begin
        # Each variable is in a column, separated by |
        row = split(strip(byline.current), "|")

        # The split will have two empty elements at either end, which are before and
        # after the | separators. We need to strip them away.
        row = row[2:length(row) - 1]

        # Remove surrounding whitespace around each value.
        row = map(strip, row)
        push!(table, row)
    end

    OKParseResult{DataTable}(table)
end

"""
    parsescenariosteps!(byline::ByLineParser)

Parse all scenario steps following a Scenario or Scenario Outline.
"""
function parsescenariosteps!(byline::ByLineParser; valid_step_types::String = "Given|When|Then")
    steps = []
    allowed_step_types = Set([Given, When, Then])

    @untilnextsection begin
        # Match Given, When, or Then on the line, or match a block text.
        # Note: This is a place where English Gherkin is hard coded.
        step_match = match(Regex("(?<step_type>$(valid_step_types)|And|But|\\*) (?<step_definition>.+)"), byline.current)
        block_text_start_match = match(r"\"\"\"", byline.current)
        data_table_start_match = match(r"^\|", strip(byline.current))

        # A line must either be a new scenario step, data table, or a block text following the previous scenario
        # step.
        if step_match === nothing && block_text_start_match === nothing && data_table_start_match === nothing
            return BadParseResult{Vector{ScenarioStep}}(:invalid_step, :step_definition, :invalid_step_definition, byline)
        end

        if data_table_start_match !== nothing
            table_result = parsetable!(byline)

            prev_step_type = typeof(steps[end])
            steps[end] = prev_step_type(steps[end].text; datatable=table_result.value)
            continue
        end

        # The current line starts a block text. Parse the rest of the block text and continue with
        # the following line.
        # Note: The method parseblocktext!(byline) consumes the current line, so it doesn't need to
        # be done here.
        if block_text_start_match !== nothing
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
        # Options: allow_any_step_order disables this check.
        step_type = step_match[:step_type]
        step_definition = step_match[:step_definition]
        if step_type == "Given"
            if !byline.options.allow_any_step_order && !(Given in allowed_step_types)
                return BadParseResult{Vector{ScenarioStep}}(:bad_step_order, :NotGiven, :Given, byline)
            end
            step = Given(step_definition)
        elseif step_type == "When"
            if !byline.options.allow_any_step_order && !(When in allowed_step_types)
                return BadParseResult{Vector{ScenarioStep}}(:bad_step_order, :NotWhen, :When, byline)
            end
            step = When(step_definition)
            delete!(allowed_step_types, Given)
        elseif step_type == "Then"
            step = Then(step_definition)
            delete!(allowed_step_types, Given)
            delete!(allowed_step_types, When)
        elseif step_type == "And" || step_type == "But" || step_type == "*"
            # A scenario step may be And, in which case it's the same type as the previous step.
            # This means that an And may not be the first scenario step.
            if isempty(steps)
                return BadParseResult{Vector{ScenarioStep}}(:leading_and, :specific_step, :and_step, byline)
            end
            last_specific_type = typeof(steps[end])
            step = last_specific_type(step_definition)
        end
        push!(steps, step)
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

        # Parse longer descriptions
        long_description_lines = []
        @untilnextstep begin
            push!(long_description_lines, strip(byline.current))
        end
        long_description = strip(join(long_description_lines, "\n"))

        # Parse scenario outline steps.
        steps_result = parsescenariosteps!(byline)
        if !issuccessful(steps_result)
            return steps_result
        end
        steps = steps_result.value

        # Consume the Example: line.
        consume!(byline)

        # Get the name of each placeholder variable.
        placeholders = split(strip(byline.current), "|")
        placeholders = placeholders[2:length(placeholders) - 1]
        placeholders = map(strip, placeholders)
        placeholders = map(String, placeholders)
        consume!(byline)

        # Parse the examples, until we hit an empty line.
        # TODO: This needs to be updated to allow for multiple Examples sections.
        examples = Array{String,2}(undef, length(placeholders), 0)
        @untilnextsection begin
            # Each variable is in a column, separated by |
            example = split(strip(byline.current), "|")

            # The split will have two empty elements at either end, which are before and
            # after the | separators. We need to strip them away.
            example = example[2:length(example) - 1]

            # Remove surrounding whitespace around each value.
            example = map(strip, example)
            examples = [examples example]
        end
        return OKParseResult{ScenarioOutline}(
            ScenarioOutline(description, tags, steps, placeholders, examples; long_description=long_description))
    end

    # Here we parse a normal Scenario instead.
    scenario_match = match(r"Scenario: (?<description>.+)", byline.current)
    if scenario_match === nothing
        return BadParseResult{Scenario}(:invalid_scenario_header, :scenario_or_outline, :invalid_header, byline)
    end

    description = scenario_match[:description]
    consume!(byline)

    # Parse longer descriptions
    long_description_lines = []
    @untilnextstep begin
        push!(long_description_lines, strip(byline.current))
    end
    long_description = strip(join(long_description_lines, "\n"))

    steps_result = parsescenariosteps!(byline)
    if !issuccessful(steps_result)
        return steps_result
    end
    steps = steps_result.value

    OKParseResult{Scenario}(Scenario(description, tags, steps, long_description=long_description))
end

function parsebackground!(byline::ByLineParser) :: ParseResult{Background}
    consumeemptylines!(byline)

    background_match = match(r"Background:(?<description>.*)", byline.current)
    if background_match !== nothing
        consume!(byline)

        steps_result = parsescenariosteps!(byline; valid_step_types = "Given")
        if !issuccessful(steps_result)
            return BadParseResult{Background}(steps_result.reason,
                                              steps_result.expected,
                                              steps_result.actual,
                                              byline)
        end
        steps = steps_result.value
        description = strip(background_match[:description])

        return OKParseResult{Background}(Background(description, steps))
    end

    OKParseResult{Background}(Background())
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
function parsefeature(text::String; options :: ParseOptions = ParseOptions()) :: ParseResult{Feature}
    byline = ByLineParser(text, options)

    try
        # Skip any leading blank lines or comments
        consumeemptylines!(byline)

        # The feature header includes all feature level tags, the description, and the long multiline
        # description.
        feature_header_result = parsefeatureheader!(byline)
        if !issuccessful(feature_header_result)
            return BadParseResult{Feature}(feature_header_result.reason,
                                           feature_header_result.expected,
                                           feature_header_result.actual,
                                           byline)
        end

        # Optionally read a Background section
        background_result = parsebackground!(byline)
        if !issuccessful(background_result)
            return BadParseResult{Feature}(background_result.reason,
                                           background_result.expected,
                                           background_result.actual,
                                           byline)
        end
        background = background_result.value

        # Each `parsescenario!`
        scenarios = AbstractScenario[]
        @ignoringemptylines begin
            scenario_parse_result = parsescenario!(byline)
            if issuccessful(scenario_parse_result)
                push!(scenarios, scenario_parse_result.value)
            else
                return BadParseResult{Feature}(scenario_parse_result)
            end
        end
        OKParseResult{Feature}(
            Feature(feature_header_result.value, background, scenarios))
    catch ex
        BadParseResult{Feature}(:exception, :nothing, Symbol(ex), byline)
    end
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