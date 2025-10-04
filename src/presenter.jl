# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
A `QuietRealTimePresenter` prints nothing as scenarios are being executed.
This is useful if you're only after a final report, after all features have been executed.
"""
struct QuietRealTimePresenter <: RealTimePresenter end
present(::QuietRealTimePresenter, ::Scenario) = nothing
present(::QuietRealTimePresenter, ::Scenario, ::ScenarioResult) = nothing
present(::QuietRealTimePresenter, ::Gherkin.ScenarioStep) = nothing
present(::QuietRealTimePresenter, ::Gherkin.ScenarioStep, ::StepExecutionResult) = nothing
present(::QuietRealTimePresenter, ::Gherkin.Feature) = nothing

"""
This presenter prints a line to the console before, during, and after a scenario. Results are color
coded.
"""
struct ColorConsolePresenter <: RealTimePresenter
    io::IO
    colors::Dict{Type, Symbol}

    function ColorConsolePresenter(io::IO = stdout)
        colors = Dict{Type, Symbol}(
            NoStepDefinitionFound => :yellow,
            NonUniqueMatch => :magenta,
            SuccessfulStepExecution => :green,
            StepFailed => :red,
            UnexpectedStepError => :light_magenta,
            SkippedStep => :light_black
        )

        new(io, colors)
    end
end

"""
    stepformat(step::ScenarioStep)

Format a step according to Gherkin syntax.
"""
stepformat(step::Given) = "Given $(step.text)"
stepformat(step::When) = " When $(step.text)"
stepformat(step::Then) = " Then $(step.text)"
stepformat(step::Gherkin.Experimental.And) = "  And $(step.text)"

"""
    stepcolor(::Presenter, ::StepExecutionResult)

Get a console color for a given result when executing a scenario step.
"""
stepcolor(presenter::Presenter, step::StepExecutionResult) = presenter.colors[typeof(step)]

"""
    stepresultmessage(::StepExecutionResult)

A human readable message for a given result.
"""
function stepresultmessage(step::StepFailed)
    if isempty(step.evaluated) || step.assertion == step.evaluated
        ["FAILED: " * step.assertion]
    else
        ["FAILED", "  Expression: " * step.assertion, "   Evaluated: " * step.evaluated]
    end
end
stepresultmessage(nomatch::NoStepDefinitionFound) = ["No match for '$(stepformat(nomatch.step))'"]
stepresultmessage(nonunique::NonUniqueMatch) = vcat(["Multiple matches found:"], ["  In " * location.filename for location in nonunique.locations])
stepresultmessage(::SuccessfulStepExecution) = []
stepresultmessage(::SkippedStep) = []
stepresultmessage(unexpected::UnexpectedStepError) = vcat(["Exception: $(string(unexpected.ex))"], ["  " * string(x) for x in unexpected.stack])
stepresultmessage(::StepExecutionResult) = []

function present(presenter::ColorConsolePresenter, feature::Feature)
    println()
    printstyled(presenter.io, "Feature: $(feature.header.description)\n"; color=:white)
end

function present(presenter::ColorConsolePresenter, scenario::Scenario)
    printstyled(presenter.io, "  Scenario: $(scenario.description)\n"; color=:blue)
end

function present(presenter::ColorConsolePresenter, scenario::Scenario, ::ScenarioResult)
    printstyled(presenter.io, "\n")
end

function present(presenter::ColorConsolePresenter, step::Gherkin.ScenarioStep)
    printstyled(presenter.io, "    $(stepformat(step))"; color=:light_cyan)
end

function present(presenter::ColorConsolePresenter, step::Gherkin.ScenarioStep, result::StepExecutionResult)
    color = stepcolor(presenter, result)
    # Clear the line by moving to the beginning and printing spaces, then move back
    # This ensures proper behavior on both Unix and Windows systems
    steptext = "    $(stepformat(step))"
    print(presenter.io, "\r", " " ^ length(steptext), "\r")
    printstyled(presenter.io, steptext, "\n"; color=color)

    resultmessage = stepresultmessage(result)
    if !isempty(resultmessage)
        # The result message may be one or more lines. Indent them all.
        s = [" " ^ 8 * x * "\n" for x in resultmessage]
        println()
        println(join(s))
    end
end
