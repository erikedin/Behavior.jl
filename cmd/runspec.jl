using ExecutableSpecifications: FromMacroStepDefinitionMatcher, executescenario, Executor
using ExecutableSpecifications: CompositeStepDefinitionMatcher
using ExecutableSpecifications: ColorConsolePresenter, present
using ExecutableSpecifications.Gherkin: parsefeature, Given, When, Then
import Base: show

stepfiles = [filename for filename in readdir("features/steps")
             if isfile(joinpath("features/steps", filename)) &&
                splitext(joinpath("features/steps", filename))[2] == ".jl"]
matchers = FromMacroStepDefinitionMatcher[]
for filename in stepfiles
    push!(matchers, FromMacroStepDefinitionMatcher(readstring(joinpath("features/steps", filename))))
end
matcher = CompositeStepDefinitionMatcher(matchers...)
executor = Executor(matcher)
presenter = ColorConsolePresenter()
featureresult = parsefeature(readstring("features/spec.feature"))
feature = featureresult.value

present(presenter, feature)
for scenario in feature.scenarios
    result = executescenario(executor, scenario)
    present(presenter, result)
    println("")
end