module Selection

export select, parsetagselector

struct TagSelector
    tag::String
end

function parsetagselector(s::String) :: TagSelector
    TagSelector(s)
end

select(ts::TagSelector, tags::AbstractVector{String}) = tags != [] && tags[1] == ts.tag

end