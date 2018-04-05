
transformoutline(outline::ScenarioOutline) = [Scenario("", [], [Given(interpolatexample(outline.steps[1].text, outline.examples[1]))])]

interpolatexample(text::String, example::String) = replace(text, r"<[^>]*>", example)