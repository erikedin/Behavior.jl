struct Engine
    accumulator::ResultAccumulator
    executor::Executor
    matcher::StepDefinitionMatcher

    function Engine(realtimepresenter::RealTimePresenter)
        matcher = CompositeStepDefinitionMatcher()
        executor = Executor(matcher, realtimepresenter)
        new(ResultAccumulator(), executor, matcher)
    end
end

addmatcher!(engine::Engine, matcher::StepDefinitionMatcher) = addmatcher!(engine.matcher, matcher)
function runfeature!(engine::Engine, feature::Feature)
    result = executefeature(engine.executor, feature)
    accumulateresult!(engine.accumulator, result)
end

finish(engine::Engine) = engine.accumulator
