
function transformoutline(outline::ScenarioOutline)
    # The examples are in a multidimensional array.
    # The size of dimension 1 is the number of placeholders.
    # The size of dimension 2 is the number of examples.
    [interpolatexample(outline, outline.examples[:,exampleindex])
     for exampleindex in 1:size(outline.examples, 2)]
end



function interpolatexample(outline::ScenarioOutline, example::Vector{String})
    placeholders_kv = ["<$(outline.placeholders[i])>" => example[i] for i in 1:length(example)]
    placeholders = Dict{String, String}(placeholders_kv...)

    fromplaceholders = x -> placeholders[x]
    steps = [interpolatestep(step, fromplaceholders) for step in outline.steps]

    Scenario(outline.description, outline.tags, steps)
end

interpolatestep(step::Given, fromplaceholders::Function) = Given(interpolatesteptext(step.text, fromplaceholders);
                                                                 block_text=interpolatesteptext(step.block_text, fromplaceholders))
interpolatestep(step::When, fromplaceholders::Function) = When(interpolatesteptext(step.text, fromplaceholders);
                                                               block_text=interpolatesteptext(step.block_text, fromplaceholders))
interpolatestep(step::Then, fromplaceholders::Function) = Then(interpolatesteptext(step.text, fromplaceholders);
                                                               block_text=interpolatesteptext(step.block_text, fromplaceholders))

interpolatesteptext(text::String, fromplaceholders::Function) = replace(text, r"<[^>]*>" => fromplaceholders)