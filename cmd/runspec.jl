using ExecutableSpecifications: FromMacroStepDefinitionMatcher, executescenario, Executor
using ExecutableSpecifications: ColorConsolePresenter, present
using ExecutableSpecifications.Gherkin: parsefeature, Given, When, Then
import Base: show

format(given::Given) = "  Given $(given.text)"
format(when::When) = "   When $(when.text)"
format(then::Then) = "   Then $(then.text)"
format(::ExecutableSpecifications.NoStepDefinitionFound) = "No step definition found!"
format(::ExecutableSpecifications.SuccessfulStepExecution) = "Succeeded!"
format(::ExecutableSpecifications.StepFailed) = "Failed!"
format(::ExecutableSpecifications.UnexpectedStepError) = "Unexpected error!"
format(::ExecutableSpecifications.SkippedStep) = "Skipped!"

matcher = FromMacroStepDefinitionMatcher(readstring("features/steps/steps.jl"))
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