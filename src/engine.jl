abstract type Engine end
abstract type OSAbstraction end

findfileswithextension(::OSAbstraction, ::String, ::String) = error("override this method")
readfile(::OSAbstraction, ::String) = error("override this method")
fileexists(::OSAbstraction, ::String) = error("override this method")

struct ExecutorEngine <: Engine
    accumulator::ResultAccumulator
    executor::Executor
    matcher::StepDefinitionMatcher

    function ExecutorEngine(realtimepresenter::RealTimePresenter;
                            executionenv=NoExecutionEnvironment())
        matcher = CompositeStepDefinitionMatcher()
        executor = Executor(matcher, realtimepresenter; executionenv=executionenv)
        new(ResultAccumulator(), executor, matcher)
    end
end

addmatcher!(engine::ExecutorEngine, matcher::StepDefinitionMatcher) = addmatcher!(engine.matcher, matcher)
function runfeature!(engine::ExecutorEngine, feature::Feature)
    result = executefeature(engine.executor, feature)
    accumulateresult!(engine.accumulator, result)
end

finish(engine::ExecutorEngine) = engine.accumulator


struct Driver
    os::OSAbstraction
    engine::Engine

    Driver(os::OSAbstraction, engine::Engine) = new(os, engine)
end

function readstepdefinitions!(driver::Driver, path::String)
    stepdefinitionfiles = findfileswithextension(driver.os, path, ".jl")
    for f in stepdefinitionfiles
        addmatcher!(driver.engine, FromMacroStepDefinitionMatcher(readfile(driver.os, f)))
    end
end

function runfeatures!(driver::Driver, path::String; parseoptions::ParseOptions = ParseOptions())
    featurefiles = findfileswithextension(driver.os, path, ".feature")
    for featurefile in featurefiles
        featureparseresult = parsefeature(readfile(driver.os, featurefile), options=parseoptions)
        feature = featureparseresult.value
        runfeature!(driver.engine, feature)
    end
    finish(driver.engine)
end