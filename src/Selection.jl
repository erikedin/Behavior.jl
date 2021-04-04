"""
Selecting which features and scenarios to run, based on tags.

# Exports

    TagSelector
    select(::TagSelector, tags::AbstractVector{String}) :: Bool
    parsetagselector(::String) :: TagSelector
"""
module Selection

using ExecutableSpecifications.Gherkin

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
    parsetagexpression(s::String) :: TagExpression

Parse the string `s` into a `TagExpression`.
"""
function parsetagexpression(s::String) :: TagExpression
    if isempty(strip(s))
        All()
    elseif startswith(s, "not ")
        tag = replace(s, "not " => "")
        Not(Tag(tag))
    else
        Tag(s)
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

end