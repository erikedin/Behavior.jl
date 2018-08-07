abstract type Engine end
abstract type OSAbstraction end

struct ExecutorEngine <: Engine
    accumulator::ResultAccumulator
    executor::Executor
    matcher::StepDefinitionMatcher

    function ExecutorEngine(realtimepresenter::RealTimePresenter)
        matcher = CompositeStepDefinitionMatcher()
        executor = Executor(matcher, realtimepresenter)
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
    engine::Engine

    Driver(os::OSAbstraction, engine::Engine) = new(engine)
end

findstepdefinitions!(driver::Driver, path::String) = addmatcher!(driver.engine, FromMacroStepDefinitionMatcher(""))