struct Engine

    Engine(realtimepresenter::RealTimePresenter) = new()
end

struct FakeResultAccumulator end
issuccess(::FakeResultAccumulator) = true

addmatcher(::Engine, ::StepDefinitionMatcher) = nothing
runfeature(::Engine, ::Feature) = nothing
finish(::Engine) = FakeResultAccumulator()
