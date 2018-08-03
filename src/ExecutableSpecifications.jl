module ExecutableSpecifications

include("Gherkin.jl")

"Abstraction for presenting results from scenario steps."
abstract type Presenter end

"Presenting results from scenario steps as they occur."
abstract type RealTimePresenter <: Presenter end

include("stepdefinitions.jl")
include("exec_env.jl")
include("executor.jl")
include("asserts.jl")
include("presenter.jl")
include("result_accumulator.jl")
include("runner.jl")

export @given, @when, @then, @expect, @beforescenario, runspec

end # module
