using ExecutableSpecifications:
    FromMacroStepDefinitionMatcher, executefeature, Executor, CompositeStepDefinitionMatcher,
    ColorConsolePresenter, present, ResultAccumulator, accumulateresult!, issuccess, featureresults
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
        push!(matchers, FromMacroStepDefinitionMatcher(read(fullpath, String); filename=fullpath))
    end
    matcher = CompositeStepDefinitionMatcher(matchers...)

    # Read all feature files.
    features = Feature[]
    for filename in featurefiles
        featureresult = parsefeature(read(joinpath("features", filename), String))
        push!(features, featureresult.value)
    end

    # The presenter will print all scenario steps as they are executed.
    presenter = ColorConsolePresenter()
    executor = Executor(matcher, presenter)
    accumulator = ResultAccumulator()

    for feature in features
        result = executefeature(executor, feature)
        accumulateresult!(accumulator, result)
    end

    println()

    #
    # Present number of scenarios that succeeded and failed for each feature
    #
    results = featureresults(accumulator)

    # Find the longest feature name, so we can align the result table.
    maxfeature = maximum(length(r.feature.header.description) for r in results)

    featureprefix = "  Feature: "
    printstyled(" " ^ (length(featureprefix) + maxfeature + 1), "| Success | Failure\n"; color=:white)
    for r in results
        linecolor = r.n_failure == 0 ? :green : :red
        printstyled(featureprefix, rpad(r.feature.header.description, maxfeature); color=linecolor)
        printstyled(" | "; color=:white)
        printstyled(rpad("$(r.n_success)", 7); color=:green)
        printstyled(" | "; color=:white)
        printstyled(rpad("$(r.n_failure)", 7), "\n"; color=linecolor)
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