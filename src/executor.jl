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

using Base.StackTraces

using Behavior.Gherkin.Experimental: And

"Executes a feature or scenario, and presents the results in real time."
struct Executor
    stepdefmatcher::StepDefinitionMatcher
    presenter::RealTimePresenter
    executionenv::ExecutionEnvironment

    Executor(matcher::StepDefinitionMatcher,
             presenter::RealTimePresenter = QuietRealTimePresenter();
             executionenv::ExecutionEnvironment = NoExecutionEnvironment()) = new(matcher, presenter, executionenv)
end

"Abstract type for a result when executing a scenario step."
abstract type StepExecutionResult end

"No matching step definition was found."
struct NoStepDefinitionFound <: StepExecutionResult
    step::Gherkin.ScenarioStep
end

"More than one matching step definition was found."
struct NonUniqueMatch <: StepExecutionResult
    locations::Vector{StepDefinitionLocation}
end

"Successfully executed a step."
struct SuccessfulStepExecution <: StepExecutionResult end

"An assert failed in the step."
struct StepFailed <: StepExecutionResult
    assertion::String
    evaluated::String

    StepFailed(assertion::AbstractString) = new(assertion, "")
    StepFailed(assertion::AbstractString, evaluated::AbstractString) = new(assertion, evaluated)
end

"An unexpected error or exception occurred during the step execution."
struct UnexpectedStepError <: StepExecutionResult
    ex::Exception
    stack::StackTrace
end

"The step was not executed."
struct SkippedStep <: StepExecutionResult end

"""
    issuccess(::StepExecutionResult)

True for successful step executions, and false otherwise.
"""
issuccess(::SuccessfulStepExecution) = true
issuccess(::StepExecutionResult) = false

"A result for a complete scenario."
struct ScenarioResult
    steps::Vector{StepExecutionResult}
    scenario::Scenario
    background::Gherkin.Background
    backgroundresult::Vector{StepExecutionResult}
end

issuccess(sr::ScenarioResult) = all(x -> issuccess(x), sr.steps)
issuccess(srs::AbstractVector{ScenarioResult}) = all(x -> issuccess(x), srs)

function executesteps(executor::Executor, context::StepDefinitionContext, steps::Vector{ScenarioStep}, isfailedyet::Bool)
    # The `steps` vector contains the results for all steps. At initialization,
    # they are all `Skipped`, because if one step fails then we stop the execution of the following
    # steps.
    results = Vector{StepExecutionResult}(undef, length(steps))
    fill!(results, SkippedStep())

    # Find a unique step definition for each step and execute it.
    # Present each step, first as it is about to be executed, and then once more with the result.
    for i = 1:length(steps)
        # If any previous step has failed, then skip all the steps that follow.
        if isfailedyet
            present(executor.presenter, steps[i])
            present(executor.presenter, steps[i], results[i])
            continue
        end

        step = steps[i]
        # Tell the presenter that this step is about to be executed.
        present(executor.presenter, step)

        results[i] = try
            # Find a step definition matching the step text.
            stepdefinitionmatch = findstepdefinition(executor.stepdefmatcher, step)

            # The block text is provided to the step definition via the context.
            context[:block_text] = step.block_text
            context.datatable = step.datatable
            try
                # Execute the step definition. Note that it's important to use `Base.invokelatest` here,
                # because otherwise it might not find that function defined yet.
                Base.invokelatest(stepdefinitionmatch.stepdefinition.definition, context, stepdefinitionmatch.variables)
            catch ex
                UnexpectedStepError(ex, stacktrace(catch_backtrace()))
            end
        catch ex
            if ex isa NoMatchingStepDefinition
                NoStepDefinitionFound(step)
            elseif ex isa NonUniqueStepDefinition
                NonUniqueMatch(ex.locations)
            else
                rethrow(ex)
            end
        end
        # Present the result after execution.
        present(executor.presenter, step, results[i])

        # If this step failed, then we skip any remaining steps.
        if !issuccess(results[i])
            isfailedyet = true
        end
    end

    results, isfailedyet
end

"""
    executescenario(::Executor, ::Gherkin.Scenario)

Execute each step in a `Scenario`. Present the results in real time.
Returns a `ScenarioResult`.
"""
function executescenario(executor::Executor, background::Gherkin.Background, scenario::Gherkin.Scenario)
    # Tell the presenter of the start of a scenario execution.
    present(executor.presenter, scenario)

    # The `context` object for a scenario execution is provided to each step,
    # so they may store intermediate values.
    context = StepDefinitionContext()

    beforescenario(executor.executionenv, context, scenario)

    # Execute the Background section
    isfailedyet = false
    backgroundresults, isfailedyet = executesteps(executor, context, background.steps, isfailedyet)

    # Execute the Scenario
    results, _isfailedyet = executesteps(executor, context, scenario.steps, isfailedyet)

    afterscenario(executor.executionenv, context, scenario)

    scenarioresult = ScenarioResult(results, scenario, background, backgroundresults)

    present(executor.presenter, scenario, scenarioresult)

    scenarioresult
end

"""
    executescenario(::Executor, ::Gherkin.ScenarioOutline)

Execute a `Scenario Outline`, which contains one or more examples. Each example is transformed into
a regular `Scenario`, and it's executed.
Reeturns a list of `ScenarioResult`s.
"""
function executescenario(executor::Executor, background::Gherkin.Background, outline::Gherkin.ScenarioOutline)
    scenarios = transformoutline(outline)
    [executescenario(executor, background, scenario)
     for scenario in scenarios]
end

"The execution result for a feature, containing one or more scenarios."
struct FeatureResult
    feature::Feature
    scenarioresults::Vector{ScenarioResult}
end

"""
    extendresults!(scenarioresults, result::ScenarioResult)
    extendresults!(scenarioresults, result::AbstractVector{ScenarioResult})

Push or append results from a feature to a list of scenario results.
"""
extendresult!(scenarioresults::AbstractVector{ScenarioResult}, result::ScenarioResult) = push!(scenarioresults, result)
extendresult!(scenarioresults::AbstractVector{ScenarioResult}, result::AbstractVector{ScenarioResult}) = append!(scenarioresults, result)

"""
    executefeature(::Executor, ::Gherkin.Feature)

Execute all scenarios and scenario outlines in a feature.
"""
function executefeature(executor::Executor, feature::Gherkin.Feature; keepgoing::Bool=true)
    # A hook that runs before each feature.
    beforefeature(executor.executionenv, feature)

    # Present that a new feature is about to be executed.
    present(executor.presenter, feature)

    # Execute each scenario and scenario outline in the feature.
    scenarioresults = ScenarioResult[]
    for scenario in feature.scenarios
        scenarioresult = executescenario(executor, feature.background, scenario)
        extendresult!(scenarioresults, scenarioresult)

        if !issuccess(scenarioresult) && !keepgoing
            break
        end
    end

    # A hook that runs after each feature
    afterfeature(executor.executionenv, feature)

    # Return a list of `ScenarioResults`.
    # Since regular scenarios return a `ScenarioResult` directly, and scenario outlines return lists
    # of `ScenarioResult`s, we have to flatten that list.
    FeatureResult(feature, reduce(vcat, scenarioresults, init=[]))
end

#
# Finding missing step implementations
#

function findmissingsteps(executor::Executor, steps::Vector{ScenarioStep}) :: Vector{ScenarioStep}
    findstep = step -> begin
        try
            findstepdefinition(executor.stepdefmatcher, step)
        catch ex
            if ex isa NoMatchingStepDefinition
                NoStepDefinitionFound(step)
            else
                rethrow(ex)
            end
        end
    end
    filter(step -> findstep(step) isa NoStepDefinitionFound, steps)
end

function findmissingsteps(executor::Executor, feature::Feature) :: Vector{ScenarioStep}
    backgroundmissingsteps = findmissingsteps(executor, feature.background.steps)

    # findmissingstep(executor, scenario.steps) returns a list of missing steps,
    # so we're creating a list of lists here. We flatten it into one list of missing steps.
    missingsteps  = Iterators.flatten([
        findmissingsteps(executor, scenario.steps)
        for scenario in feature.scenarios
    ])

    # We call unique to remove duplicate steps.
    # We check uniqueness using only the step text, ignoring block text
    # and data tables.
    unique(step -> step.text, vcat(collect(missingsteps), backgroundmissingsteps))
end

function stepimplementationsuggestion(steptype::String, text::String) :: String
    # Escaping the string here ensures that the step text is a valid Julia string.
    # If the text is
    #   some precondition with $x and a quote "
    # then the $x will be interpreted as string interpolation by Julia, which is
    # not what we intend. Also, the " needs to be escaped so we don't have mismatched
    # double quotes.
    escaped_text = escape_string(text, "\$\"")
    """$steptype(\"$(escaped_text)\") do context
        @fail "Implement me"
    end
    """
end
stepimplementationsuggestion(given::Given) :: String = stepimplementationsuggestion("@given", given.text)
stepimplementationsuggestion(when::When) :: String = stepimplementationsuggestion("@when", when.text)
stepimplementationsuggestion(then::Then) :: String = stepimplementationsuggestion("@then", then.text)
# For now, just default missing And steps to Given, because we don't keep track of what the previous
# actual step was.
stepimplementationsuggestion(then::And) :: String = stepimplementationsuggestion("@given", then.text)

function suggestmissingsteps(executor::Executor, feature::Feature) :: String
    missingsteps = findmissingsteps(executor, feature)

    missingstepimpls = [
        stepimplementationsuggestion(step)
        for step in missingsteps
    ]

    missingstepcode = join(missingstepimpls, "\n\n")

    if isempty(missingstepimpls)
        ""
    else
        """
        using Behavior

        $(missingstepcode)
        """
    end
end

#
# Interpolation of Scenario Outlines
#

function transformoutline(outline::ScenarioOutline)
    # The examples are in a multidimensional array.
    # The size of dimension 1 is the number of placeholders.
    # The size of dimension 2 is the number of examples.
    [interpolatexample(outline, example)
     for example in outline.examples]
end



function interpolatexample(outline::ScenarioOutline, example::Vector{T}) where {T <: AbstractString}
    # Create placeholders on the form `<foo>` for each placeholder `foo`, and map it against the
    # value for this particular example.
    #
    # An example Scenario Outline could have two placeholders `foo` and `bar`:
    #    Scenario Outline: An example
    #       When some action <foo>
    #       Then some postcondition <bar>
    #
    #    Examples:
    #    | foo | bar |
    #    | 1   | 2   |
    #    | 17  | 42  |
    #
    # The parsed Scenario Outline object already has a list of the placeholders `foo` and `bar`.
    # This method is called twice, once with example vector `[1, 2]` and once with `[17, 42]`.
    #
    placeholders_kv = ["<$(outline.placeholders[i])>" => example[i] for i in 1:length(example)]
    placeholders = Dict{String, T}(placeholders_kv...)

    # `interpolatestep` just creates a new scenario step of the same type, but with all occurrences
    # of placeholders replace with the example value.
    fromplaceholders = x -> placeholders[x]
    steps = ScenarioStep[interpolatestep(step, fromplaceholders) for step in outline.steps]

    Scenario(outline.description, outline.tags, steps)
end

interpolatestep(step::Given, fromplaceholders::Function) = Given(interpolatesteptext(step.text, fromplaceholders);
                                                                 block_text=interpolatesteptext(step.block_text, fromplaceholders),
                                                                 datatable=step.datatable)
interpolatestep(step::When, fromplaceholders::Function) = When(interpolatesteptext(step.text, fromplaceholders);
                                                               block_text=interpolatesteptext(step.block_text, fromplaceholders),
                                                               datatable=step.datatable)
interpolatestep(step::Then, fromplaceholders::Function) = Then(interpolatesteptext(step.text, fromplaceholders);
                                                               block_text=interpolatesteptext(step.block_text, fromplaceholders),
                                                               datatable=step.datatable)
interpolatestep(step::And, fromplaceholders::Function) = And(interpolatesteptext(step.text, fromplaceholders);
                                                               block_text=interpolatesteptext(step.block_text, fromplaceholders),
                                                               datatable=step.datatable)

interpolatesteptext(text::String, fromplaceholders::Function) = replace(text, r"<[^>]*>" => fromplaceholders)