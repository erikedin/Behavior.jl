using ExecutableSpecifications: FromMacroStepDefinitionMatcher, executefeature, Executor
using ExecutableSpecifications: CompositeStepDefinitionMatcher
using ExecutableSpecifications: ColorConsolePresenter, present
using ExecutableSpecifications.Gherkin: parsefeature, Given, When, Then, Feature
import Base: show

function allfileswithext(path::String, extension::String)
    [filename for filename in readdir(path)
              if isfile(joinpath(path, filename)) &&
              splitext(joinpath(path, filename))[2] == extension]
end

# Find all step definition files and all feature files.
stepfiles = allfileswithext("features/steps", ".jl")
featurefiles = allfileswithext("features", ".feature")

# Read all step definition files.
matchers = FromMacroStepDefinitionMatcher[]
for filename in stepfiles
    push!(matchers, FromMacroStepDefinitionMatcher(readstring(joinpath("features/steps", filename))))
end
matcher = CompositeStepDefinitionMatcher(matchers...)

# Read all feature files.
features = Feature[]
for filename in featurefiles
    featureresult = parsefeature(readstring(joinpath("features", filename)))
    push!(features, featureresult.value)
end

# The presenter will print all scenario steps as they are executed.
presenter = ColorConsolePresenter()
executor = Executor(matcher, presenter)

for feature in features
    executefeature(executor, feature)
end

println()