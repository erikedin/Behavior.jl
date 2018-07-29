using Base.StackTraces

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
end

"""
    executescenario(::Executor, ::Gherkin.Scenario)

Execute each step in a `Scenario`. Present the results in real time.
Returns a `ScenarioResult`.
"""
function executescenario(executor::Executor, scenario::Gherkin.Scenario)
    # Tell the presenter of the start of a scenario execution.
    present(executor.presenter, scenario)

    # The `context` object for a scenario execution is provided to each step,
    # so they may store intermediate values.
    context = StepDefinitionContext()

    beforescenario(executor.executionenv, context, scenario)

    # The `steps` vector contains the results for all steps. At initialization,
    # they are all `Skipped`, because if one step fails then we stop the execution of the following
    # steps.
    steps = Vector{StepExecutionResult}(undef, length(scenario.steps))
    fill!(steps, SkippedStep())

    # Keep track of which the last executed step is. This could be removed if the code was shuffled
    # a bit below.
    lastexecutedstep = 0

    # Find a unique step definition for each step and execute it.
    # Present each step, first as it is about to be executed, and then once more with the result.
    for i = 1:length(scenario.steps)
        # Tell the presenter that this step is about to be executed.
        present(executor.presenter, scenario.steps[i])

        steps[i] = try
            # Find a step definition matching the step text.
            stepdefinition = findstepdefinition(executor.stepdefmatcher, scenario.steps[i])
            try
                # Execute the step definition. Note that it's important to use `Base.invokelatest` here,
                # because otherwise it might not find that function defined yet.
                Base.invokelatest(stepdefinition.definition, context)
            catch ex
                UnexpectedStepError(ex, stacktrace(catch_backtrace()))
            end
        catch ex
            if ex isa NoMatchingStepDefinition
                NoStepDefinitionFound(scenario.steps[i])
            elseif ex isa NonUniqueStepDefinition
                NonUniqueMatch(ex.locations)
            else
                rethrow(ex)
            end
        end
        # Present the result after execution.
        present(executor.presenter, scenario.steps[i], steps[i])
        lastexecutedstep = i

        # If this step failed, then we skip any remaining steps.
        if !issuccess(steps[i])
            break
        end
    end

    # Present any remaining steps as skipped.
    for k = lastexecutedstep + 1:length(scenario.steps)
        present(executor.presenter, scenario.steps[k])
        present(executor.presenter, scenario.steps[k], steps[k])
    end

    afterscenario(executor.executionenv, context, scenario)

    ScenarioResult(steps, scenario)
end

"""
    executescenario(::Executor, ::Gherkin.ScenarioOutline)

Execute a `Scenario Outline`, which contains one or more examples. Each example is transformed into
a regular `Scenario`, and it's executed.
Reeturns a list of `ScenarioResult`s.
"""
function executescenario(executor::Executor, outline::Gherkin.ScenarioOutline)
    scenarios = transformoutline(outline)
    [executescenario(executor, scenario)
     for scenario in scenarios]
end

"The execution result for a feature, containing one or more scenarios."
struct FeatureResult
    feature::Feature
    scenarioresults::Vector{ScenarioResult}
end

"""
    executefeature(::Executor, ::Gherkin.Feature)

Execute all scenarios and scenario outlines in a feature.
"""
function executefeature(executor::Executor, feature::Gherkin.Feature)
    # Present that a new feature is about to be executed.
    present(executor.presenter, feature)

    # Execute each scenario and scenario outline in the feature.
    scenarioresults = [executescenario(executor, s) for s in feature.scenarios]

    # Return a list of `ScenarioResults`.
    # Since regular scenarios return a `ScenarioResult` directly, and scenario outlines return lists
    # of `ScenarioResult`s, we have to flatten that list.
    FeatureResult(feature, reduce(vcat, scenarioresults, init=[]))
end

#
# Interpolation of Scenario Outlines
#

function transformoutline(outline::ScenarioOutline)
    # The examples are in a multidimensional array.
    # The size of dimension 1 is the number of placeholders.
    # The size of dimension 2 is the number of examples.
    [interpolatexample(outline, outline.examples[:,exampleindex])
     for exampleindex in 1:size(outline.examples, 2)]
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