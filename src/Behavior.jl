module Behavior

include("Gherkin.jl")
include("Selection.jl")

"Abstraction for presenting results from scenario steps."
abstract type Presenter end

"Presenting results from scenario steps as they occur."
abstract type RealTimePresenter <: Presenter end

include("stepdefinitions.jl")
include("exec_env.jl")
include("executor.jl")
include("asserts.jl")
include("presenter.jl")
include("terse_presenter.jl")
include("result_accumulator.jl")
include("engine.jl")
include("runner.jl")

export @given, @when, @then, @expect, @fail, @beforescenario, @afterscenario, runspec
export suggestmissingsteps

end # module
