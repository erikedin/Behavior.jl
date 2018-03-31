using ExecutableSpecifications: FromMacroStepDefinitionMatcher, executefeature, Executor
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
presenter = ColorConsolePresenter()
executor = Executor(matcher, presenter)
featureresult = parsefeature(readstring("features/spec.feature"))
feature = featureresult.value

executefeature(executor, feature)

println()