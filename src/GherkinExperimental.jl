# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Experimental

import Base: (|), show

using Behavior.Gherkin: Given, When, Then, Scenario, ScenarioStep, AbstractScenario
using Behavior.Gherkin: Feature, FeatureHeader, Background, DataTableRow, DataTable
using Behavior.Gherkin: ScenarioOutline

struct GherkinSource
    lines::Vector{String}

    GherkinSource(source::String) = new(split(strip(source), "\n"))
end

notempty(s) = !isempty(strip(s))
notcomment(s) = !startswith(strip(s), "#")
defaultlinecondition(s) = notempty(s) && notcomment(s)
anyline(s) = true

struct ParserState
    nextline::Int
    nextchar::Int

    ParserState() = new(1, 1)
    ParserState(nextline::Int, nextchar::Int) = new(nextline, nextchar)
end

isendofline(state::ParserState, source::GherkinSource) = state.nextchar > lastindex(source.lines[state.nextline])
islastline(state::ParserState, source::GherkinSource) = state.nextline == lastindex(source.lines)
ispastlastline(state::ParserState, source::GherkinSource) = state.nextline > lastindex(source.lines)
iseof(state::ParserState, source::GherkinSource) = ispastlastline(state, source) || islastline(state, source) && isendofline(state, source)


consume(state::ParserState, nlines::Int) = ParserState(state.nextline + nlines, 1)
function consumechar(initialstate::ParserState, source::GherkinSource) :: Tuple{Char, ParserState}
    state = if isendofline(initialstate, source)
        # Start of next line
        ParserState(initialstate.nextline + 1, 1)
    else
        initialstate
    end
    c = source.lines[state.nextline][state.nextchar]
    (c, ParserState(state.nextline, state.nextchar + 1))
end

function consumechars(state::ParserState, source::GherkinSource, n::Int) :: Tuple{String, ParserState}
    # Indexes: 123456
    # Example: abcdef
    thisline = source.lines[state.nextline]

    # If nextchar = 2 (b)
    #    n = 3
    # thislastindex = 2 + 3 - 1 = 4
    # so the result should be bcd
    # Protect against indexing past the end of the string by checking lastindex too.
    thislastindex = min(state.nextchar + n - 1, lastindex(thisline))
    s = thisline[state.nextchar : thislastindex]
    (s, ParserState(state.nextline, state.nextchar + n))
end

function Base.show(io::IO, state::ParserState)
    println(io, "$(state.nextline):$(state.nextchar)")
end

"""
    ParserInput

ParserInput encapsulates
- the Gherkin source
- the parser state (current line and character)
- the parser line operation (not implemented yet)
"""
struct ParserInput
    source::GherkinSource
    state::ParserState
    condition::Function

    ParserInput(source::String) = new(GherkinSource(source), ParserState(), defaultlinecondition)
    ParserInput(input::ParserInput, newstate::ParserState) = new(input.source, newstate, defaultlinecondition)
    ParserInput(input::ParserInput, condition::Function) = new(input.source, input.state, condition)
end

consume(input::ParserInput, n::Int) :: ParserInput = ParserInput(input, consume(input.state, n))
function consumechar(input::ParserInput) :: Tuple{Char, ParserInput}
    c, newstate = consumechar(input.state, input.source)
    c, ParserInput(input, newstate)
end
function consumechars(input::ParserInput, n::Int) :: Tuple{String, ParserInput}
    s, newstate = consumechars(input.state, input.source, n)
    s, ParserInput(input, newstate)
end

function line(input::ParserInput) :: Tuple{Union{Nothing, String}, ParserInput}
    nextline = findfirst(input.condition, input.source.lines[input.state.nextline:end])
    if nextline === nothing
        return nothing, input
    end
    strip(input.source.lines[input.state.nextline + nextline - 1]), consume(input, nextline)
end

iseof(input::ParserInput) = iseof(input.state, input.source)

"""
    Parser{T}

A Parser{T} is a callable that takes a ParserInput and produces
a ParseResult{T}. The parameter T is the type of what it parses.
"""
abstract type Parser{T} end

"""
    ParseResult{T}

A ParseResult{T} is the either successful or failed result of trying to parse
a value of T from the input.
"""
abstract type ParseResult{T} end

"""
    OKParseResult{T}(value::T)

OKParseResult{T} is a successful parse result.
"""
struct OKParseResult{T} <: ParseResult{T}
    value::T
    newinput::ParserInput
end

"""
    BadParseResult{T}

BadParseResult{T} is an abstract supertype for all failed parse results.
"""
abstract type BadParseResult{T} <: ParseResult{T} end

"""
    isparseok(::ParseResult{T})

isparseok returns true for successful parse results, and false for unsuccessful ones.
"""

isparseok(::OKParseResult{T}) where {T} = true
isparseok(::BadParseResult{T}) where {T} = false

struct BadExpectationParseResult{T} <: BadParseResult{T}
    expected::String
    actual::String
    newinput::ParserInput
end

struct BadUnexpectedParseResult{T} <: BadParseResult{T}
    unexpected::String
    newinput::ParserInput
end

struct BadInnerParseResult{S, T} <: BadParseResult{T}
    inner::ParseResult{<:S}
    newinput::ParserInput
end

function Base.show(io::IO, result::BadInnerParseResult{S, T}) where {S, T}
    show(io, result.inner)
end
function Base.show(io::IO, mime::MIME"text/plain", result::BadInnerParseResult{S, T}) where {S, T}
    show(io, mime, result.inner)
end

struct BadCardinalityParseResult{S, T} <: BadParseResult{T}
    inner::BadParseResult{S}
    atleast::Int
    actual::Int
    newinput::ParserInput
end

struct BadUnexpectedEOFParseResult{T} <: BadParseResult{T}
    newinput::ParserInput
end

struct BadExpectedEOFParseResult{T} <: BadParseResult{T}
    newinput::ParserInput
end

function Base.show(io::IO, result::BadExpectedEOFParseResult{T}) where {T}
    s, _newinput = line(result.newinput)
    println(io, "Expected EOF but found at line $(result.newinput.state):")
    println(io)
    println(io, "  $s")
end

struct BadExceptionParseResult{T} <: BadParseResult{T}
    ex
end

function Base.show(io::IO, result::BadExceptionParseResult{T}) where {T}
    show(io, "Exception: $(result.ex)")
end

"""
    charP

Consume a single character.
"""
struct charC <: Parser{Char} end

function (parser::charC)(input::ParserInput)
    if iseof(input)
        BadUnexpectedEOFParseResult{Char}(input)
    else
        c, newinput = consumechar(input)
        OKParseResult{Char}(c, newinput)
    end
end

const charP = charC()

"""
    repeatC(inner, n)

Repeat a parser n times.
"""
struct repeatC{T} <: Parser{Vector{T}}
    inner::Parser{T}
    n::Int
end

function (parser::repeatC{T})(input::ParserInput) where {T}
    values = T[]
    currentinput = input
    for i in 1:parser.n
        result = charP(currentinput)
        if isparseok(result)
            push!(values, result.value)
        else
            return BadInnerParseResult{T, Vector{T}}(result, input)
        end
        currentinput = result.newinput
    end
    OKParseResult{Vector{T}}(values, currentinput)
end

"""
    result |> f

Apply some function f to the OK parse result.
Any bad parse result is simply returned.
"""
Base.:(|>)(result::OKParseResult{T}, f::Function) where {T} = f(result)
Base.:(|>)(result::BadParseResult{T}, ::Function) where {T} = result

"""
    satisfyC()

Given some parser, accept the result if it satisfies some condition.
"""
struct satisfyC{T} <: Parser{T}
    condition::Function
    p::Parser{T}
end

function (parser::satisfyC{T})(input::ParserInput) :: ParseResult{T} where {T}
    s = okresult -> if parser.condition(okresult.value)
        okresult
    else
        BadUnexpectedParseResult{T}(string(okresult.value), input)
    end
    charP(input) |> s
end

"""
    choiceC

Choose between one of two parsers.
"""
struct choiceC{S, T} <: Parser{Union{S, T}}
    one::Parser{S}
    two::Parser{T}
end

function (parser::choiceC{S, T})(input::ParserInput) :: ParseResult{Union{S, T}} where {S, T}
    result = parser.one(input)
    if isparseok(result)
        result
    else
        parser.two(input)
    end
end

"""
    EscapeChar

A character escaped with a backslash.
"""
struct EscapeChar
    c::Char
end
Base.print(io::IO, e::EscapeChar) = print(io, e.c)
const CharOrEscape = Union{Char, EscapeChar}

"""
    escapeP

Parse a character that is possibly an escape sequenced character.
"""
struct escapeC <: Parser{CharOrEscape} end

function (parser::escapeC)(input::ParserInput) :: ParseResult{CharOrEscape}
    result = charP(input)
    if isparseok(result)
        if result.value == '\\'
            escresult = charP(result.newinput)
            if isparseok(escresult)
                OKParseResult{CharOrEscape}(EscapeChar(escresult.value), escresult.newinput)
            else
                BadInnerParseResult{Char, CharOrEscape}(escresult, result.newinput)
            end
        else
            OKParseResult{CharOrEscape}(result.value, result.newinput)
        end
    else
        BadInnerParseResult{Char, CharOrEscape}(result, result.newinput)
    end
end

const escapeP = escapeC()

"""
    EscapedChar()

Parse a single character, that is possibly an escape sequence.
"""
struct EscapedChar <: Parser{Char} end

function (parser::EscapedChar)(input::ParserInput) :: ParseResult{Char}
    if iseof(input)
        return BadUnexpectedEOFParseResult{Char}(input)
    end
    c, newinput = consumechar(input)
    if c == '\\'
        # TODO: Currently, the only escape sequence we need is \|, so we just fetch
        # the next char and return that. However, other sequences will need to be
        # converted from one character to another.
        escape, newinput = consumechar(newinput)
        OKParseResult{Char}(escape, newinput)
    else
        OKParseResult{Char}(c, newinput)
    end
end

"""
    Line(expected::String)

Line is a parser that recognizes when a line is exactly an expected value.
It returns the expected value if it is found, or a bad parse result if not.
"""
struct Line <: Parser{String}
    expected::String
end

function (parser::Line)(input::ParserInput) :: ParseResult{String}
    s, newinput = line(input)

    if s === nothing
        BadUnexpectedEOFParseResult{String}(input)
    elseif s == parser.expected
        OKParseResult{String}(parser.expected, newinput)
    else
        BadExpectationParseResult{String}(parser.expected, s, input)
    end
end

"""
    Literal

Parse a known literal value, useful for keywords and delimiters.
"""
struct Literal <: Parser{String}
    expected::String
end

function (parser::Literal)(input::ParserInput) :: ParseResult{String}
    charparser = repeatC(charP, length(parser.expected))
    result = charparser(input)
    if isparseok(result)
        s = join(result.value)
        if s == parser.expected
            OKParseResult{String}(s, result.newinput)
        else
            BadUnexpectedParseResult{String}(s, input)
        end
    else
        BadInnerParseResult{Vector{Char}, String}(result, input)
    end
end

"""
    Optionally{T}

Optionally{T} parses a value of type T if the inner parser succeeds, or nothing
if the inner parser fails. It always succeeds.
"""
struct Optionally{T} <: Parser{Union{Nothing, T}}
    inner::Parser{T}
end

function (parser::Optionally{T})(input::ParserInput) :: ParseResult{Union{Nothing, T}} where {T}
    result = parser.inner(input)
    if isparseok(result)
        OKParseResult{Union{Nothing, T}}(result.value, result.newinput)
    else
        OKParseResult{Union{Nothing, T}}(nothing, input)
    end
end

"""
    optionalordefault(value, default)

Return `value` if it is not nothing, default otherwise.
"""
function optionalordefault(value, default)
    if value === nothing
        default
    else
        value
    end
end

"""
    Or{T}(::Parser{T}, ::Parser{T})

Or matches either of the provided parsers. It short-circuits.
"""
struct Or{T} <: Parser{T}
    inners::Vector{Parser{<:T}}

    function Or{T}(inners::Parser{<:T}...) where {T}
        new{T}([inners...])
    end
end

function (parser::Or{T})(input::ParserInput) :: ParseResult{<:T} where {T}
    #result = parser.a(input)
    #if isparseok(result)
    #    result
    #else
    #    parser.b(input)
    #end
    result = nothing
    for inner in parser.inners
        result = inner(input)
        if isparseok(result)
            return result
        end
    end
    result
end

(|)(a::Parser{T}, b::Parser{T}) where {T} = Or{T}(a, b)

"""
    Transformer{S, T}

Transforms a parser of type S to a parser of type T, using a transform function.
"""
struct Transformer{S, T} <: Parser{T}
    inner::Parser{S}
    transform::Function
end

function (parser::Transformer{S, T})(input::ParserInput) where {S, T}
    result = parser.inner(input)
    if isparseok(result)
        newvalue = parser.transform(result.value)
        OKParseResult{T}(newvalue, result.newinput)
    else
        BadInnerParseResult{S, T}(result, input)
    end
end

"""
    Sequence{T}

Combine parsers into a sequence, that matches all of them in order.
"""
struct Sequence{T} <: Parser{Vector{T}}
    inner::Vector{Parser{<:T}}

    Sequence{T}(parsers...) where {T} = new(collect(parsers))
end

function (parser::Sequence{T})(input::ParserInput) :: ParseResult{Vector{T}} where {T}
    values = Vector{T}()
    currentinput = input

    for p in parser.inner
        result = p(currentinput)
        if isparseok(result)
            push!(values, result.value)
            currentinput = result.newinput
        else
            return BadInnerParseResult{T, Vector{T}}(result, input)
        end
    end

    OKParseResult{Vector{T}}(values, currentinput)
end

"""
    Joined

Joins a sequence of strings together into one string.
"""
Joined(inner::Parser{Vector{String}}) = Transformer{Vector{String}, String}(inner, x -> join(x, "\n"))

nostopcondition(_input::ParserInput, _result::ParseResult{T}) where {T} = false

"""
    Repeating{T}

Repeats the provided parser until it no longer recognizes the input.
"""
struct Repeating{T} <: Parser{Vector{T}}
    inner::Parser{T}
    atleast::Int
    stopcondition::Function

    Repeating{T}(inner::Parser{T}; atleast::Int = 0, stopcondition::Function = nostopcondition) where {T} = new(inner, atleast, stopcondition)
end

function (parser::Repeating{T})(input::ParserInput) :: ParseResult{Vector{T}} where {T}
    values = Vector{T}()
    currentinput = input

    while true
        result = parser.inner(currentinput)
        if !isparseok(result) || parser.stopcondition(currentinput, result)
            cardinality = length(values)
            if cardinality < parser.atleast
                return BadCardinalityParseResult{T, Vector{T}}(result, parser.atleast, cardinality, input)
            end
            break
        end
        push!(values, result.value)
        currentinput = result.newinput
    end

    OKParseResult{Vector{T}}(values, currentinput)
end

"""
    LineIfNot

Consumes a line if it does not match a given parser.
"""
struct LineIfNot <: Parser{String}
    inner::Parser{<:Any}
    linecondition::Function

    LineIfNot(inner::Parser{<:Any}) = new(inner, defaultlinecondition)
    LineIfNot(inner::Parser{<:Any}, condition::Function) = new(inner, condition)
end

function (parser::LineIfNot)(realinput::ParserInput) :: ParseResult{String}
    # This parser has support for providing the inner parser with a
    # non-default line condition.
    input = ParserInput(realinput, parser.linecondition)
    result = parser.inner(input)
    if isparseok(result)
        badline, _badinput = line(input)
        BadUnexpectedParseResult{String}(string(badline), input)
    else
        s, newinput = line(input)
        if s === nothing
            BadUnexpectedEOFParseResult{String}(input)
        else
            OKParseResult{String}(s, newinput)
        end
    end
end

"""
    StartsWith

Consumes a line if it starts with a given string.
"""
struct StartsWith <: Parser{String}
    prefix::String
end

function (parser::StartsWith)(input::ParserInput) :: ParseResult{String}
    s, newinput = line(input)
    if s === nothing
        BadUnexpectedEOFParseResult{String}(input)
    elseif startswith(s, parser.prefix)
        OKParseResult{String}(s, newinput)
    else
        BadExpectationParseResult{String}(parser.prefix, s, input)
    end
end

struct EOFParser <: Parser{Nothing} end

function (parser::EOFParser)(input::ParserInput) :: ParseResult{Nothing}
    s, newinput = line(input)
    if s === nothing
        OKParseResult{Nothing}(nothing, newinput)
    else
        BadExpectedEOFParseResult{Nothing}(input)
    end
end

"""
    EscapedStringParser

Parse a string that potentially has escape sequences in it.

:param stopat: Stop when this literal is encountered

# Example
Parse a column in a markdown table

    | foo | bar |

The delimiter is the pipe character (|) and the EscapedStringParser could be used
to parse "foo" and "bar", and the parser will stop when discovering the delimiter..
"""
function EscapedStringParser(stopat::String) :: Parser{String}
    # Stop repeating the EscapedChar parser when the current input is the
    # delimiter literal.
    # Example: Stop reading when the end of this column is found by the literal |
    isdelimiterliteral = (input, _result) -> isparseok(Literal(stopat)(input))
    Transformer{Vector{Char}, String}(Repeating{Char}(EscapedChar(), stopcondition=isdelimiterliteral), join)
end

##
## Gherkin-specific parser
##

takeelement(i::Int) = xs -> xs[i]

"""
    BlockText

Parses a Gherkin block text.
"""
BlockText() = Transformer{Vector{String}, String}(
    Sequence{String}(
        Line("\"\"\""),
        Joined(Repeating{String}(LineIfNot(Line("\"\"\""), anyline))),
        Line("\"\"\""),
    ),
    takeelement(2)
)

struct Keyword
    keyword::String
    rest::String
end

"""
    DataTableParser()

Consumes a data table in a scenario step.

## Example

    | Header 1 | Header 2 |
    | Foo      | Bar      |
    | Baz      | Quux     |
"""
struct DataTableRowParser <: Parser{DataTableRow} end

function (parser::DataTableRowParser)(input::ParserInput) :: ParseResult{DataTableRow}
    s, newinput = line(input)
    if s === nothing
        return BadUnexpectedEOFParseResult{DataTableRow}(input)
    end
    parts = split(s, "|")

    if length(parts) >= 3
        columns = collect([strip(p) for p in parts if strip(p) != ""])
        OKParseResult{DataTableRow}(columns, newinput)
    else
        BadExpectationParseResult{DataTableRow}("| column 1 | column 2 | ... | column n |", s, input)
    end
end

struct DataTableRowsParser <: Parser{Vector{DataTableRow}}
end

function (parser::DataTableRowsParser)(input::ParserInput) :: ParseResult{Vector{DataTableRow}}
    rowparser = Sequence{String}(
        Literal("|"),
        EscapedStringParser("|"),
        Literal("|"),
    )
    result = rowparser(input)
    s = strip(result.value[2])
    OKParseResult{Vector{DataTableRow}}([[s]], input)
end

DataTableParser(; usenew::Bool = false) = Transformer{Vector{DataTableRow}, DataTable}(
    if usenew DataTableRowsParser() else Repeating{DataTableRow}(DataTableRowParser(), atleast=1) end,
    rows -> rows
)

# tablecellP parses a single cell in a data table.
struct tablecellC <: Parser{String} end

function (parser::tablecellC)(input::ParserInput) :: ParseResult{String}
    seq = Sequence{String}(
        Literal("abc"),
        Literal("|")
    )
    # Take only the first element of the sequence.
    p = Transformer{Vector{String}, String}(
        seq,
        takeelement(1)
    )
    p(input)
end

const tablecellP = tablecellC()

struct AnyLine <: Parser{String} end

function (parser::AnyLine)(input::ParserInput) :: ParseResult{String}
    s, newinput = line(input)
    if s === nothing
        BadUnexpectedEOFParseResult{String}(input)
    else
        OKParseResult{String}(s, newinput)
    end
end

Splitter(inner::Parser{String}, delimiter) :: Parser{Vector{String}} = Transformer{String, Vector{String}}(
    inner,
    s -> split(s, delimiter, keepempty=false)
)

struct Validator{T} <: Parser{Vector{T}}
    inner::Parser{Vector{T}}
    f::Function
end

function (parser::Validator{T})(input::ParserInput) :: ParseResult{Vector{T}} where {T}
    result = parser.inner(input)
    if isparseok(result) && all(parser.f, result.value)
        OKParseResult{Vector{T}}(result.value, result.newinput)
    else
        BadInnerParseResult{Vector{T}, Vector{T}}(result, input)
    end
end

const TagList = Vector{String}

"""
    TagParser()

Consumes a single tag in the form `@tagname`.
"""
TagParser() :: Parser{TagList} = Validator{String}(Splitter(AnyLine(), isspace), x -> startswith(x, "@"))

"""
    TagLinesParser()

Read tags until they stop.
"""
TagLinesParser() :: Parser{TagList} = Transformer{Vector{TagList}, TagList}(
    Repeating{TagList}(TagParser()),
    taglines -> vcat(taglines...)
)

"""
    KeywordParser

Recognizes a keyword, and any following text on the same line.
"""
KeywordParser(word::String) = Transformer{String, Keyword}(
    StartsWith(word),
    s -> begin
        Keyword(word, strip(replace(s, word => "", count=1)))
    end
)

const TableOrBlockTextTypes = Union{String, DataTable}
const DataTableOrBlockText = (
    Sequence{TableOrBlockTextTypes}(DataTableParser(), BlockText()) |
    Sequence{TableOrBlockTextTypes}(BlockText(), DataTableParser()) |
    Sequence{TableOrBlockTextTypes}(BlockText()) |
    Sequence{TableOrBlockTextTypes}(DataTableParser())
)
const StepPieces = Union{Keyword, Union{Nothing, Vector{TableOrBlockTextTypes}}}

mutable struct StepBuilder{T}
    steptype::Type{T}
    keyword::Keyword
    blocktext::String
    datatable::DataTable

    StepBuilder{T}(steptype::Type{T}, keyword::Keyword) where {T} = new(steptype, keyword, "", DataTable())
end

accumulate!(sb::StepBuilder{T}, table::DataTable) where {T} = sb.datatable = table
accumulate!(sb::StepBuilder{T}, blocktext::String) where {T} = sb.blocktext = blocktext
accumulate!(sb::StepBuilder{T}, vs::Vector{TableOrBlockTextTypes}) where {T} = foreach(v -> accumulate!(sb, v), vs)
accumulate!(::StepBuilder{T}, ::Nothing) where {T} = nothing

buildstep(sb::StepBuilder{T}) where {T} = sb.steptype(sb.keyword.rest, block_text=sb.blocktext, datatable=sb.datatable)

function StepParser(steptype::Type{T}, keyword::String) :: Parser{T} where {T}
    Transformer{Vector{StepPieces}, T}(
        Sequence{StepPieces}(KeywordParser(keyword), Optionally(DataTableOrBlockText)),
        sequence -> begin
            keyword = sequence[1]
            stepbuilder = StepBuilder{T}(steptype, keyword)

            accumulate!(stepbuilder, sequence[2])

            buildstep(stepbuilder)
        end
    )
end

"""
    And

An `And` type scenario step
"""
struct And <: ScenarioStep
    text::String
    block_text::String
    datatable::DataTable

    And(text::AbstractString; block_text = "", datatable=DataTable()) = new(text, block_text, datatable)
end


"""
    GivenParser

Consumes a Given step.
"""
GivenParser() = StepParser(Given, "Given ")
WhenParser() = StepParser(When, "When ")
ThenParser() = StepParser(Then, "Then ")
AndParser() = StepParser(And, "And ")
ButParser() = StepParser(And, "But ")
StarParser() = StepParser(And, "* ")

# TODO Find a way to express this as
#      GivenParser() | WhenParser() | ThenParser()
const AnyStepParser = Or{ScenarioStep}(
    GivenParser(), WhenParser(), ThenParser(), AndParser(), ButParser(), StarParser()
)
"""
    StepsParser

Parses zero or more steps.
"""
StepsParser() = Repeating{ScenarioStep}(AnyStepParser)

const AnyKeyword = (
    KeywordParser("Given ") |
    KeywordParser("When ") |
    KeywordParser("Then ") |
    KeywordParser("Feature:") |
    KeywordParser("Scenario:") |
    KeywordParser("Scenario Outline:") |
    KeywordParser("Background:") |
    KeywordParser("Rule:")
)
const MaybeTags = Union{Nothing, Vector{String}}
const ScenarioBits = Union{Keyword, String, Vector{ScenarioStep}, MaybeTags}


const LongDescription = Joined(Repeating{String}(LineIfNot(AnyKeyword)))
"""
    ScenarioParser()

Consumes a Scenario.
"""
ScenarioParser() = Transformer{Vector{ScenarioBits}, Scenario}(
    Sequence{ScenarioBits}(
        Optionally(TagLinesParser()),
        KeywordParser("Scenario:"),
        Optionally(LongDescription),
        StepsParser()),
    sequence -> begin
        tags = optionalordefault(sequence[1], [])
        keyword = sequence[2]
        longdescription = optionalordefault(sequence[3], "")
        Scenario(keyword.rest, tags, Vector{ScenarioStep}(sequence[4]), long_description=longdescription)
    end
)

const ScenarioOutlineBits = Union{Keyword, String, Vector{ScenarioStep}, MaybeTags, DataTable}
"""
    ScenarioOutlineParser()

Consumes a Scenario Outline.
"""
ScenarioOutlineParser() = Transformer{Vector{ScenarioOutlineBits}, ScenarioOutline}(
    Sequence{ScenarioOutlineBits}(
        Optionally(TagLinesParser()),
        KeywordParser("Scenario Outline:"),
        Optionally(LongDescription),
        StepsParser(),
        Line("Examples:") | Line("Scenarios:"),
        DataTableParser()
    ),
    sequence -> begin
        tags = optionalordefault(sequence[1], [])
        keyword = sequence[2]
        longdescription = optionalordefault(sequence[3], "")
        steps = sequence[4]
        examples = sequence[6]
        # The DataTableParser guarantees at least 1 row.
        placeholders = examples[1]
        ScenarioOutline(
            keyword.rest,
            tags,
            steps,
            placeholders,
            examples[2:end],
            long_description=longdescription
        )
    end
)

const BackgroundBits = ScenarioBits
"""
    BackgroundParser()

Consume a Background.
"""
BackgroundParser() = Transformer{Vector{BackgroundBits}, Background}(
    Sequence{BackgroundBits}(
        KeywordParser("Background:"),
        Optionally(LongDescription),
        StepsParser()
    ),
    sequence -> begin
        keyword = sequence[1]
        longdescription = optionalordefault(sequence[2], "")
        Background(keyword.rest, sequence[3], long_description=longdescription)
    end
)

struct Rule <: AbstractScenario
    description::String
    longdescription::String
    scenarios::Vector{AbstractScenario}
    tags::Vector{String}
end

const ScenarioList = Vector{Scenario}
const RuleBits = Union{Keyword, MaybeTags, Nothing, String, ScenarioList}

"""
    RuleParser

Consumes a Rule and its child scenarios.
"""
RuleParser() = Transformer{Vector{RuleBits}, Rule}(
    Sequence{RuleBits}(
        Optionally(TagLinesParser()),
        KeywordParser("Rule:"),
        Optionally(LongDescription),
        Repeating{Scenario}(ScenarioParser())),
    sequence -> begin
        tags = optionalordefault(sequence[1], String[])
        keyword = sequence[2]
        longdescription = optionalordefault(sequence[3], "")
        scenarios = sequence[4]
        Rule(keyword.rest, longdescription, scenarios, tags)
    end
)

const FeatureBits = Union{Keyword, String, Background, Nothing, Vector{AbstractScenario}, MaybeTags}
"""
    FeatureParser

Consumes a full feature file.
"""
const ScenarioOrRule = Or{AbstractScenario}(
    Or{AbstractScenario}(ScenarioParser(), ScenarioOutlineParser()),
    RuleParser()
)

# The long descriptions in features have different ending conditions than in a
# scenario, so we have separate parsers for them.
ScenarioOrBackground() = Or{Any}(ScenarioOrRule, BackgroundParser())
const LongFeatureDescription = Joined(Repeating{String}(LineIfNot(ScenarioOrBackground())))

FeatureParser() = Transformer{Vector{FeatureBits}, Feature}(
    Sequence{FeatureBits}(
        Optionally(TagLinesParser()),
        KeywordParser("Feature:"),
        Optionally(LongFeatureDescription),
        Optionally(BackgroundParser()),
        Repeating{AbstractScenario}(ScenarioOrRule)),
    sequence -> begin
        keyword = sequence[2]
        tags = optionalordefault(sequence[1], String[])
        longdescription = optionalordefault(sequence[3], "")
        background = optionalordefault(sequence[4], Background())
        Feature(FeatureHeader(keyword.rest, [longdescription], tags), background, sequence[5])
    end
)

const FeatureFileBits = Union{Feature, Nothing}
FeatureFileParser() = Transformer{Vector{FeatureFileBits}, Feature}(
    Sequence{FeatureFileBits}(FeatureParser(), EOFParser()),
    takeelement(1)
)

##
## Exports
##

export ParserInput, OKParseResult, BadParseResult, isparseok

# Basic combinators
export Line, Optionally, Or, Transformer, Sequence
export Joined, Repeating, LineIfNot, StartsWith, EOFParser

# Gherkin combinators
export BlockText, KeywordParser
export StepsParser, GivenParser, WhenParser, ThenParser
export ScenarioParser, RuleParser, FeatureParser, FeatureFileParser, BackgroundParser
export DataTableParser, TagParser, TagLinesParser, ScenarioOutlineParser

# Data carrier types
export Keyword, Rule

end