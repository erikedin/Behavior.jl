using ExecutableSpecifications:
    FromMacroStepDefinitionMatcher, executefeature, Executor, CompositeStepDefinitionMatcher,
    ColorConsolePresenter, present, ResultAccumulator, accumulateresult, issuccess
using ExecutableSpecifications.Gherkin: parsefeature, Given, When, Then, Feature

function allfileswithext(path::String, extension::String)
    [filename for filename in readdir(path)
              if isfile(joinpath(path, filename)) &&
                 splitext(joinpath(path, filename))[2] == extension]
end

function runspec()
    # Find all step definition files and all feature files.
    stepfiles = allfileswithext("features/steps", ".jl")
    featurefiles = allfileswithext("features", ".feature")

    # Read all step definition files.
    matchers = FromMacroStepDefinitionMatcher[]
    for filename in stepfiles
        fullpath = joinpath("features/steps", filename)
        push!(matchers, FromMacroStepDefinitionMatcher(readstring(fullpath); filename=fullpath))
    end
    matcher = CompositeStepDefinitionMatcher(matchers...)

    # Read all feature files.
    features = Feature[]
    for filename in featurefiles
        featureresult = parsefeature(readstring(joinpath("features", filename)))
        push!(features, featureresult.value)
    end

    # The presenter will print all scenario steps as they are executed.
    presenter = ColorConsolePresenter()
    executor = Executor(matcher, presenter)
    accumulator = ResultAccumulator()

    for feature in features
        result = executefeature(executor, feature)
        accumulateresult(accumulator, result)
    end

    println()

    istotalsuccess = issuccess(accumulator)
    if istotalsuccess
        println("SUCCESS")
    else
        println("FAILURE")
    end

    istotalsuccess
end