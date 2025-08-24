# Behavior

![CI](https://github.com/erikedin/Behavior.jl/actions/workflows/ci.yml/badge.svg)

BDD is an acronym for _Behaviour Driven Development_. It is a process for creating and verifying
requirements, written in such a way that they can be executed as code. This package aims to be a
tool for executing such requirements, and creating reports.

# Usage
See [docs/src/usage.md](docs/src/usage.md) for more detailed usage.

See [docs/src/tutorial.md](docs/src/tutorial.md) for a step-by-step introduction to this package.

Specifications are written in the Gherkin format, such as

```gherkin
Feature: Making coffee

    Scenario: Making a cup of coffee
        Given that there is a cup in the coffee machine
         When the "Coffee" button is pressed
         Then the cup is filled with coffee
```

For each `Given`, `When`, and `Then` line, a corresponding method is written, which is executed when
that line is reached.

```julia
using Behavior
using CoffeeMachine

hascoffee(cup::Cup) = cup[:coffee] > 0.0

@given("that there is a cup in the coffee machine") do context
    cup = Cup()
    machine = Machine()

    cupisinthemachine(machine, cup)

    context[:cup] = cup
    context[:machine] = machine
end

@when("the \"Coffee\" button is pressed") do context
    machine = context[:machine]
    coffeewaspressed(machine)
end

@then("the cup is filled with coffee") do context
    cup = context[:cup]
    @expect hascoffee(cup)
end
```

Feature files have extension `.feature`, and are stored in the `features` directory (see
"Current state" for current limitations), and step definitions (the executable code) have the
extension `.jl` and are stored in `features/steps`.

# Example project
The project [CoffeeMachine.jl](https://github.com/erikedin/CoffeeMachine.jl) is an example of how to
use Behavior.jl.

# Running
Run the command line tool `runspec.jl` from the directory containing the `features` directory, or
from the Julia REPL with

```julia
julia> using Behavior
julia> runspec()
```

See "Current state" for limitations.

# Changes in v0.5.0
There have been a number of fixes between v0.4.0 and v0.5.0, and unfortunately over a 4 year time period.
The majority of the work has been on improving the Gherkin parser.

- The new Gherkin parser is now the default
- Some other changes

To change the parser back to the old one, in case of issues, use `ParserOptions` with
`use_experimental = false`, like this:

```julia
parseoptions = Behavior.Gherkin.ParseOptions(use_experimental=false)
runspec(parseoptions=parseoptions)
```

# Current state
The package is not feature complete, but is absolutely in a usable state. It is also under active
development.

These are some current limitations and missing features, that will be lifted as development progresses:

- [ ] Currently does not function in Julia 1.4 and probably not before
- [ ] Presenting the results of scenarios is very rudimentary.
- [ ] Step definition variables do not yet have type information.
- [ ] Gherkin Rules support

## Completed

- [x] Reads feature files from anywhere under `features`.
- [x] Reads step files from anywhere under `features/steps`.
- [x] Variables in step definition strings.


# License
Behavior.jl is licensed under the Apache License version 2.0.
