struct QuietRealTimePresenter <: RealTimePresenter end
present(::QuietRealTimePresenter, ::Scenario) = nothing

struct ColorConsolePresenter <: Presenter
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

function present(presenter::Presenter, scenarioresult::ScenarioResult)
    print_with_color(:blue, presenter.io, "  Scenario: $(scenarioresult.scenario.description)\n")
    for i = 1:length(scenarioresult.steps)
        stepresult = scenarioresult.steps[i]
        step = scenarioresult.scenario.steps[i]
        print_with_color(stepcolor(presenter, stepresult), presenter.io, "    $(stepformat(step))\n")
    end
end

function present(presenter::Presenter, feature::Feature)
    print_with_color(:white, presenter.io, "Feature: $(feature.header.description)\n")
    println()
end
