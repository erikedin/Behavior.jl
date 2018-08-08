using ExecutableSpecifications:
    ExecutorEngine, ColorConsolePresenter, Driver,
    readstepdefinitions!, runfeatures!, issuccess,
    FromSourceExecutionEnvironment, NoExecutionEnvironment
import ExecutableSpecifications:
    findfileswithextension, readfile, fileexists

struct OSAL <: ExecutableSpecifications.OSAbstraction end
function findfileswithextension(::OSAL, path::String, extension::String)
    [joinpath(path, filename) for filename in readdir(path)
              if isfile(joinpath(path, filename)) &&
                 splitext(joinpath(path, filename))[2] == extension]
end

readfile(::OSAL, path::String) = read(path, String)
fileexists(::OSAL, path::String) = isfile(path)

"""
    runspec()

Execute all features found from the current directory, or another specified directory.
"""
function runspec(rootpath::String = ".")
    featurepath = joinpath(rootpath, "features")
    stepspath = joinpath(featurepath, "steps")
    execenvpath = joinpath(featurepath, "environment.jl")
    os = OSAL()

    executionenv = if fileexists(os, execenvpath)
        FromSourceExecutionEnvironment(readfile(os, execenvpath))
    else
        NoExecutionEnvironment()
    end

    engine = ExecutorEngine(ColorConsolePresenter(); executionenv=executionenv)
    driver = Driver(os, engine)

    readstepdefinitions!(driver, stepspath)
    resultaccumulator = runfeatures!(driver, featurepath)

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

    istotalsuccess = issuccess(resultaccumulator)
    if istotalsuccess
        println("SUCCESS")
    else
        println("FAILURE")
    end

    istotalsuccess
end