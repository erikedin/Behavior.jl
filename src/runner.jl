using ExecutableSpecifications:
    ExecutorEngine, ColorConsolePresenter, Driver,
    readstepdefinitions!, runfeatures!, issuccess,
    FromSourceExecutionEnvironment, NoExecutionEnvironment
import ExecutableSpecifications:
    findfileswithextension, readfile, fileexists

using ExecutableSpecifications.Gherkin: BadParseResult
using Glob

struct OSAL <: ExecutableSpecifications.OSAbstraction end
function findfileswithextension(::OSAL, path::String, extension::String)
    return rglob("*$extension", path)
end

readfile(::OSAL, path::String) = read(path, String)
fileexists(::OSAL, path::String) = isfile(path)

"""
    rglob(pattern, path)

Find files recursively. 
"""
rglob(pattern, path) = Base.Iterators.flatten(map(d -> glob(pattern, d[1]), walkdir(path)))

function parseonly(featurepath::String; parseoptions::ParseOptions=ParseOptions())

    # -----------------------------------------------------------------------------
    # borrowed code from runspec; should be refactored later
    os = OSAL()
    engine = ExecutorEngine(ColorConsolePresenter(); executionenv=NoExecutionEnvironment())
    driver = Driver(os, engine)
    # -----------------------------------------------------------------------------

    featurefiles = rglob("*.feature", featurepath)

    # Parse all feature files and collect results to an array of named tuples
    results = []
    for featurefile in featurefiles
        try
            parseddata = parsefeature(readfile(driver.os, featurefile), options=parseoptions)
            isbad = parseddata isa BadParseResult
            push!(results, (filename = featurefile, success = !isbad, result = parseddata))
        catch ex
            push!(results, (filename = featurefile, success = false, result = BadParseResult{Feature}(:exception, :nothing, Symbol("$ex"), 0, "")))
        end
    end
    return results
end

"""
    printbadparseresult(error::BadParseResult{T})

Print parse errors.
"""
function printbadparseresult(featurefile::String, err::Gherkin.BadParseResult{T}) where {T}
    println("ERROR: $(featurefile):$(err.linenumber)")
    println("      Line: $(err.line)")
    println("    Reason: $(err.reason)")
    println("  Expected: $(err.expected)")
    println("    Actual: $(err.actual)")
end

"""
    runspec(rootpath; featurepath, stepspath, execenvpath, parseoptions)

Execute all features found from the `rootpath`.

By default, it looks for feature files in `<rootpath>/features` and step files
`<rootpath>/features/steps`. An `environment.jl` file may be added to 
`<rootpath>/features` directory for running certain before/after code.
You may override the default locations by specifying `featurepath`, 
`stepspath`, or `execenvpath`.

See also: [Gherkin.ParseOptions](@ref).
"""
function runspec(
    rootpath::String = ".";
    featurepath = joinpath(rootpath, "features"),
    stepspath = joinpath(featurepath, "steps"),
    execenvpath = joinpath(featurepath, "environment.jl"),
    parseoptions::ParseOptions=ParseOptions(),
    presenter::RealTimePresenter=ColorConsolePresenter()
)
    os = OSAL()

    executionenv = if fileexists(os, execenvpath)
        FromSourceExecutionEnvironment(readfile(os, execenvpath))
    else
        NoExecutionEnvironment()
    end

    engine = ExecutorEngine(presenter; executionenv=executionenv)
    driver = Driver(os, engine)

    readstepdefinitions!(driver, stepspath)
    resultaccumulator = runfeatures!(driver, featurepath, parseoptions=parseoptions)

    if isempty(resultaccumulator)
        println("No features found.")
        return true
    end

    #
    # Present number of scenarios that succeeded and failed for each feature
    #
    results = featureresults(resultaccumulator)

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

    #
    # Present any syntax errors
    #
    for (featurefile, err) in resultaccumulator.errors
        println()
        printbadparseresult(featurefile, err)
    end

    println()

    istotalsuccess = issuccess(resultaccumulator)
    if istotalsuccess
        println("SUCCESS")
    else
        println("FAILURE")
    end

    istotalsuccess
end

"""
    suggestmissingsteps(featurepath::String, stepspath::String; parseoptions::ParseOptions=ParseOptions())

Find missing steps from the feature and print suggestions on step implementations to
match those missing steps.
"""
function suggestmissingsteps(
    featurepath::String,
    stepspath = joinpath(dirname(featurepath), "steps");
    parseoptions::ParseOptions=ParseOptions())

    # All of the below is quite hacky, which I'm motivating by the fact that
    # I just want something working. It most definitely indicates that I need to rework the whole
    # Driver/ExecutorEngine design.

    # -----------------------------------------------------------------------------
    # borrowed code from runspec; should be refactored later
    os = OSAL()
    engine = ExecutorEngine(QuietRealTimePresenter(); executionenv=NoExecutionEnvironment())
    driver = Driver(os, engine)

    readstepdefinitions!(driver, stepspath)
    # Parse the feature file and suggest missing steps.
    parseresult = parsefeature(read(featurepath, String), options=parseoptions)
    if parseresult isa BadParseResult
        println("Failed to parse feature file $featurepath")
        println(parseresult)
        return
    end

    feature = parseresult.value

    suggestedcode = suggestmissingsteps(driver.engine.executor, feature)
    println(suggestedcode)
end