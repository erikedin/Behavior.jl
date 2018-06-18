using Base.StackTraces

struct Executor
    stepdefmatcher::StepDefinitionMatcher
    presenter::RealTimePresenter

    Executor(matcher::StepDefinitionMatcher, presenter::RealTimePresenter = QuietRealTimePresenter()) = new(matcher, presenter)
end

abstract type StepExecutionResult end

struct NoStepDefinitionFound <: StepExecutionResult
    step::Gherkin.ScenarioStep
end
struct NonUniqueMatch <: StepExecutionResult
    locations::Vector{StepDefinitionLocation}
end
struct SuccessfulStepExecution <: StepExecutionResult end
struct StepFailed <: StepExecutionResult
    assertion::String
end
struct UnexpectedStepError <: StepExecutionResult
    ex::Exception
    stack::StackTrace
end
struct SkippedStep <: StepExecutionResult end

issuccess(::SuccessfulStepExecution) = true
issuccess(::StepExecutionResult) = false

struct ScenarioResult
    steps::Vector{StepExecutionResult}
    scenario::Scenario
end

function executescenario(executor::Executor, scenario::Gherkin.Scenario)
    present(executor.presenter, scenario)
    context = StepDefinitionContext()
    steps = Vector{StepExecutionResult}(undef, length(scenario.steps))
    fill!(steps, SkippedStep())
    lastexecutedstep = 0

    # Find a unique step definition for each step and execute it.
    # Present each step, first as it is about to be executed, and then once more with the result.
    for i = 1:length(scenario.steps)
        present(executor.presenter, scenario.steps[i])
        steps[i] = try
            stepdefinition = findstepdefinition(executor.stepdefmatcher, scenario.steps[i])
            try
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
        present(executor.presenter, scenario.steps[i], steps[i])
        lastexecutedstep = i
        if !issuccess(steps[i])
            break
        end
    end

    # Present any remaining steps as skipped.
    for k = lastexecutedstep + 1:length(scenario.steps)
        present(executor.presenter, scenario.steps[k])
        present(executor.presenter, scenario.steps[k], steps[k])
    end

    ScenarioResult(steps, scenario)
end

function executescenario(executor::Executor, outline::Gherkin.ScenarioOutline)
    scenarios = transformoutline(outline)
    [executescenario(executor, scenario)
     for scenario in scenarios]
end

struct FeatureResult
    feature::Feature
    scenarioresults::Vector{ScenarioResult}
end

function executefeature(executor::Executor, feature::Gherkin.Feature)
    present(executor.presenter, feature)
    scenarioresults = [executescenario(executor, s) for s in feature.scenarios]
    FeatureResult(feature, reduce(vcat, [], scenarioresults))
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
    placeholders_kv = ["<$(outline.placeholders[i])>" => example[i] for i in 1:length(example)]
    placeholders = Dict{String, T}(placeholders_kv...)

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