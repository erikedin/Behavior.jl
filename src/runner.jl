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

using Behavior:
    ExecutorEngine, ColorConsolePresenter, Driver,
    readstepdefinitions!, runfeatures!, issuccess,
    FromSourceExecutionEnvironment, NoExecutionEnvironment
import Behavior:
    findfileswithextension, readfile, fileexists

using Behavior.Gherkin
using Behavior.Gherkin.Experimental
using Glob

struct OSAL <: Behavior.OSAbstraction end
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
        if parseoptions.use_experimental
            try
                input = Experimental.ParserInput(read(featurefile, String))
                featureparser = Experimental.FeatureFileParser()
                result = featureparser(input)
                if Experimental.isparseok(result)
                    push!(results, (filename = featurefile, success = true, result = result.value))
                else
                    push!(results, (filename = featurefile, success = false, result = result))
                end
            catch ex
                push!(results, (filename = featurefile, success = false, result = Experimental.BadExceptionParseResult{Feature}(ex)))
            end
        else
            try
                parseddata = parsefeature(readfile(driver.os, featurefile), options=parseoptions)
                isbad = parseddata isa BadParseResult
                push!(results, (filename = featurefile, success = !isbad, result = parseddata))
            catch ex
                push!(results, (filename = featurefile, success = false, result = Gherkin.BadParseResult{Feature}(:exception, :nothing, Symbol("$ex"), 0, "")))
            end
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
    runspec(rootpath; featurepath, stepspath, execenvpath, parseoptions, presenter, tags)

Execute all features found from the `rootpath`.

By default, it looks for feature files in `<rootpath>/features` and step files
`<rootpath>/features/steps`. An `environment.jl` file may be added to
`<rootpath>/features` directory for running certain before/after code.
You may override the default locations by specifying `featurepath`,
`stepspath`, or `execenvpath`.

The `tagselector` option is an expression you can use to select which scenarios to run
based on tags. For instance, the tag selector `@foo` will run only those scenarios that
have the tag `@foo`, while `not @ignore` will run only that scenarios that _do not_ have
the `@ignore` tag.

See also: [Gherkin.ParseOptions](@ref).
"""
function runspec(
    rootpath::String = ".";
    featurepath = joinpath(rootpath, "features"),
    stepspath = joinpath(featurepath, "steps"),
    execenvpath = joinpath(featurepath, "environment.jl"),
    parseoptions::ParseOptions=ParseOptions(),
    presenter::RealTimePresenter=ColorConsolePresenter(),
    tags::String = "",
    break_by_error::Bool = false,
)
    os = OSAL()

    executionenv = if fileexists(os, execenvpath)
        FromSourceExecutionEnvironment(readfile(os, execenvpath))
    else
        NoExecutionEnvironment()
    end

    # set the environment variable for make it possible to break up the test
    # run after the first failure occurse
    GlobalExecEnv.envs[:break_after_error] = (() -> break_by_error)


    if parseoptions.use_experimental
        println("WARNING: Experimental parser used for feature files!")
        println()
    end

    # TODO: Handle tag selector errors once the syntax is more complex.
    selector = Selection.parsetagselector(tags)

    engine = ExecutorEngine(presenter; executionenv=executionenv, selector=selector)
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
    suggestmissingsteps(featurepath::String, stepspath::String; parseoptions::ParseOptions=ParseOptions(), tagselector::String = "")

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
    BadParseResultTypes = Union{Gherkin.BadParseResult{Feature}, Experimental.BadParseResult{Feature}}

    parseresult = if parseoptions.use_experimental
        println("WARNING: suggestmissingsteps is using the experimental Gherkin parser")
        input = ParserInput(read(featurepath, String))
        parser = Experimental.FeatureFileParser()
        parser(input)
    else
        parsefeature(read(featurepath, String), options=parseoptions)
    end
    if parseresult isa BadParseResultTypes
        println("Failed to parse feature file $featurepath")
        println(parseresult)
        return
    end

    feature = parseresult.value

    suggestedcode = suggestmissingsteps(driver.engine.executor, feature)
    println(suggestedcode)
end
