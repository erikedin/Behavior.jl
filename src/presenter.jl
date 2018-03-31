struct QuietRealTimePresenter <: RealTimePresenter end
present(::QuietRealTimePresenter, ::Scenario) = nothing
present(::QuietRealTimePresenter, ::Gherkin.ScenarioStep) = nothing
present(::QuietRealTimePresenter, ::Gherkin.ScenarioStep, ::StepExecutionResult) = nothing
present(::QuietRealTimePresenter, ::Gherkin.Feature) = nothing


struct ColorConsolePresenter <: RealTimePresenter
    io::IO
    colors::Dict{Type, Symbol}

    function ColorConsolePresenter(io::IO = STDOUT)
        colors = Dict{Type, Symbol}(
            NoStepDefinitionFound => :yellow,
            SuccessfulStepExecution => :green,
            StepFailed => :red,
            UnexpectedStepError => :light_magenta,
            SkippedStep => :light_black
        )

        new(io, colors)
    end
end

stepformat(step::Given) = "Given $(step.text)"
stepformat(step::When) = " When $(step.text)"
stepformat(step::Then) = " Then $(step.text)"

stepcolor(presenter::Presenter, step::StepExecutionResult) = presenter.colors[typeof(step)]

function present(presenter::ColorConsolePresenter, feature::Feature)
    println()
    print_with_color(:white, presenter.io, "Feature: $(feature.header.description)\n")
end

function present(presenter::ColorConsolePresenter, scenario::Scenario)
    println()
    print_with_color(:blue, presenter.io, "  Scenario: $(scenario.description)\n")
end

function present(presenter::ColorConsolePresenter, step::Gherkin.ScenarioStep)
    print_with_color(:light_cyan, presenter.io, "    $(stepformat(step))")
end

function present(presenter::ColorConsolePresenter, step::Gherkin.ScenarioStep, result::StepExecutionResult)
    color = stepcolor(presenter, result)
    print_with_color(color, presenter.io, "\r    $(stepformat(step))\n")
end
