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

"""
Selecting which features and scenarios to run, based on tags.

# Exports

    TagSelector
    select(::TagSelector, tags::AbstractVector{String}) :: Bool
    parsetagselector(::String) :: TagSelector
"""
module Selection

using Behavior.Gherkin

export select, parsetagselector, TagSelector

"""
Abstract type for a tag expression.
Each tag expression can be matched against a set of tags.
"""
abstract type TagExpression end

"""
    matches(ex::TagExpression, tags::AbstractVector{String}) :: Bool

Returns true if `tags` matches the tag expression `ex`, false otherwise.
This must be implemented for each `TagExpression` subtype.
"""
matches(::TagExpression, tags::AbstractVector{String}) :: Bool = error("Implement this in TagExpression types")

"""
Tag is an expression that matches against a single tag.

It will match if the tag in the `value` is in the `tags` set.
"""
struct Tag <: TagExpression
    value::String
end
matches(ex::Tag, tags::AbstractVector{String}) = ex.value in tags

"""
Not matches a tag set if and only if the `inner` tag expression _does not_ match.
"""
struct Not <: TagExpression
    inner::TagExpression
end
matches(ex::Not, tags::AbstractVector{String}) = !matches(ex.inner, tags)

"""
All is a tag expression that matches any tags or no tags.
"""
struct All <: TagExpression end
matches(::All, ::AbstractVector{String}) = true

"""
Any matches any tags in a list.
"""
struct Any <: TagExpression
    exs::Vector{TagExpression}
end
matches(anyex::Any, tags::AbstractVector{String}) = any(ex -> matches(ex, tags), anyex.exs)

"""
    Or(::TagExpression, ::TagExpression)

Match either expression.
"""
struct Or <: TagExpression
    a::TagExpression
    b::TagExpression
end

"""
    Parentheses(::TagExpression)

An expression in parentheses.
"""
struct Parentheses <: TagExpression
    ex::TagExpression
end

"""
    parsetagexpression(s::String) :: TagExpression

Parse the string `s` into a `TagExpression`.
"""
function parsetagexpression(s::String) :: TagExpression
    if isempty(strip(s))
        All()
    elseif startswith(s, "not ")
        tag = replace(s, "not " => "")
        Not(parsetagexpression(tag))
    else
        tags = split(s, ",")
        Any([Tag(t) for t in tags])
    end
end

"""
TagSelector is used to select a feature or scenario based on its tags.

The `TagSelector` is created by parsing a tag expression in string form. Then the
`select` method can be used to query if a given feature or scenario should be selected for execution.
"""
struct TagSelector
    expression::TagExpression
end

"""
    selectscenario(::TagSelector, feature::Feature, scenario::Scenario) :: Boolean

Check if a given scenario ought to be included in the execution. Returns true if that is the case,
false otherwise.
"""
function select(ts::TagSelector, feature::Feature, scenario::Gherkin.AbstractScenario) :: Bool
    tags = vcat(feature.header.tags, scenario.tags)
    matches(ts.expression, tags)
end

"""
    select(::TagSelector, feature::Feature) :: Union{Feature,Nothing}

Filter a feature and its scenarios based on the selected tags.
Returns a feature with zero or more scenarios, or nothing if the feature
and none of the scenarios matched the tag selector.
"""
function select(ts::TagSelector, feature::Feature) :: Feature
    newscenarios = [scenario
                    for scenario in feature.scenarios
                    if select(ts, feature, scenario)]
    Feature(feature, newscenarios)
end

"""
    parsetagselector(s::String) :: TagSelector

Parse a string into a `TagSelector` struct. This can then be used with the `select` query to determine
if a given feature or scenario should be selected for execution.

# Examples
```julia-repl
julia> # Will match any feature/scenario with the tag @foo
julia> parsetagselector("@foo")

julia> # Will match any feature/scenario without the tag @bar
julia> parsetagselector("not @bar")
```
"""
function parsetagselector(s::String) :: TagSelector
    TagSelector(parsetagexpression(s))
end

const AllScenarios = TagSelector(All())

##
## Parser combinators for tag expressions
##
## This will soonish replace most of the code above.
##

struct TagExpressionInput
    source::String
    position::Int

    function TagExpressionInput(source::String, position::Int = 1)
        nextnonwhitespace = findnext(c -> c != ' ', source, position)
        newposition = if nextnonwhitespace !== nothing
            nextnonwhitespace
        else
            length(source) + 1
        end
        new(source, newposition)
    end
end

currentchar(input::TagExpressionInput) = (input.source[input.position], TagExpressionInput(input.source, input.position + 1))
iseof(input::TagExpressionInput) = input.position > length(input.source)

abstract type ParseResult{T} end

struct OKParseResult{T} <: ParseResult{T}
    value::T
    newinput::TagExpressionInput
end

struct BadParseResult{T} <: ParseResult{T}
    newinput::TagExpressionInput
end

abstract type TagExpressionParser{T} end

"""
    AnyTagExpression()

Consumes any type of tag expression. The actual parser constructor is defined further down below,
after all expression types have been defined.
"""
struct AnyTagExpression <: TagExpressionParser{TagExpression} end



"""
    NotIn(::String)

Take a single character if it is not one of the specified forbidden values.
"""
struct NotIn <: TagExpressionParser{Char}
    notchars::String
end

function (parser::NotIn)(input::TagExpressionInput) :: ParseResult{Char}
    if iseof(input)
        return BadParseResult{Char}(input)
    end

    c, newinput = currentchar(input)
    if contains(parser.notchars, c)
        BadParseResult{Char}(input)
    else
        OKParseResult{Char}(c, newinput)
    end
end

"""
    Repeating(::TagExpressionParser)

Repeat a given parser while it succeeds.
"""
struct Repeating{T} <: TagExpressionParser{Vector{T}}
    inner::TagExpressionParser{T}
end

function (parser::Repeating{T})(input::TagExpressionInput) :: ParseResult{Vector{T}} where {T}
    result = Vector{T}()
    currentinput = input

    while true
        innerresult = parser.inner(currentinput)
        if innerresult isa BadParseResult{T}
            break
        end
        push!(result, innerresult.value)
        currentinput = innerresult.newinput
    end

    OKParseResult{Vector{T}}(result, currentinput)
end

"""
    Transforming(::TagExpressionParser, f::Function)

Transforms an OK parse result using a provided function
"""
struct Transforming{S, T} <: TagExpressionParser{T}
    inner::TagExpressionParser{S}
    f::Function
end

function (parser::Transforming{S, T})(input::TagExpressionInput) :: ParseResult{T}  where {S, T}
    result = parser.inner(input)
    if result isa OKParseResult{S}
        OKParseResult{T}(parser.f(result.value), result.newinput)
    else
        BadParseResult{T}(input)
    end
end

struct TakeUntil <: TagExpressionParser{String}
    anyof::String
end
function (parser::TakeUntil)(input::TagExpressionInput) :: ParseResult{String}
    delimiterindex = findnext(c -> contains(parser.anyof, c), input.source, input.position)
    lastindex = if delimiterindex !== nothing
        delimiterindex - 1
    else
        length(input.source)
    end
    s = input.source[input.position:lastindex]
    OKParseResult{String}(s, TagExpressionInput(input.source, lastindex + 1))
end

SingleTagParser() = Transforming{Vector{String}, Tag}(
    SequenceParser{String}(
        Literal("@"),
        TakeUntil("() "),
    ),
    s -> Tag(join(s)))

"""
    SequenceParser{T}(parsers...)

Consumes a sequence of other parsers.
"""
struct SequenceParser{T} <: TagExpressionParser{Vector{T}}
    inner::Vector{TagExpressionParser{<:T}}

    SequenceParser{T}(parsers...) where {T} = new(collect(parsers))
end

function (parser::SequenceParser{T})(input::TagExpressionInput) :: ParseResult{Vector{T}} where {T}
    values = Vector{T}()
    currentinput = input

    for p in parser.inner
        result = p(currentinput)
        
        if result isa BadParseResult
            return BadParseResult{Vector{T}}(input)
        end

        push!(values, result.value)
        currentinput = result.newinput
    end

    OKParseResult{Vector{T}}(values, currentinput)
end

"""
    Literal(::String)

Consumes an exact literal string.
"""
struct Literal <: TagExpressionParser{String}
    value::String
end

function (parser::Literal)(input::TagExpressionInput) :: ParseResult{String}
    n = length(parser.value)
    endposition = min(input.position + n - 1, length(input.source))
    actual = input.source[input.position:endposition]
    if parser.value == actual
        OKParseResult{String}(actual, TagExpressionInput(input.source, endposition + 1))
    else
        BadParseResult{String}(input)
    end
end

const NotBits = Union{String, TagExpression}
"""
    NotTagParser()

Consumes a logical not of some tag expression.
"""
NotTagParser() = Transforming{Vector{NotBits}, Not}(
    SequenceParser{NotBits}(
        Literal("not"),
        AnyTagExpression()
    ),
    xs -> Not(xs[2])
)

const OrBits = Union{String, TagExpression}
"""
    OrParser()

Consumes a logical or expression.
"""
OrParser() = Transforming{Vector{OrBits}, Or}(
    # TODO Support tag expressions here
    SequenceParser{OrBits}(
        SingleTagParser(),
        Literal("or"),
        SingleTagParser()
    ),
    xs -> Or(xs[1], xs[3])
)

# TODO Create And expression parser

const ParenthesesBits = Union{String, TagExpression}
"""
    ParenthesesParser()

Consumes a tag expression in parentheses.
"""
ParenthesesParser() = Transforming{Vector{ParenthesesBits}, Parentheses}(
    SequenceParser{ParenthesesBits}(
        Literal("("),
        AnyTagExpression(),
        Literal(")")
    ),
    xs -> Parentheses(xs[2])
)

"""
    AnyOfParser(parsers...)

Consume any of the supplied parsers.
"""
struct AnyOfParser <: TagExpressionParser{TagExpression}
    parsers::Vector{TagExpressionParser{<:TagExpression}}

    AnyOfParser(parsers...) = new(collect(parsers))
end

function (parser::AnyOfParser)(input::TagExpressionInput) :: ParseResult{TagExpression}
    results = Vector{OKParseResult{<:TagExpression}}()

    for p in parser.parsers
        result = p(input)
        if result isa OKParseResult
            push!(results, result)
        end
    end

    if isempty(results)
        BadParseResult{TagExpression}(input)
    else
        # Return the longest successful parse
        resultlength = result -> result.newinput.position - input.position
        maxresultlength = maximum(resultlength, results)
        maxresultindex = findfirst(result -> resultlength(result) == maxresultlength, results)
        maxresult = results[maxresultindex]
        OKParseResult{TagExpression}(maxresult.value, maxresult.newinput)
    end
end

#
# The empty AnyTagExpression constructor is defined here at the bottom, where it
# can find all expression types.
#

function (::AnyTagExpression)(input::TagExpressionInput) :: ParseResult{TagExpression}
    inner = AnyOfParser(
        NotTagParser(),
        ParenthesesParser(),
        OrParser(),
        SingleTagParser(),
    )
    inner(input)
end

end