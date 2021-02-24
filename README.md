# ExecutableSpecifications

[![codecov.io](http://codecov.io/github/erikedin/ExecutableSpecifications.jl/coverage.svg?branch=master)](http://codecov.io/github/erikedin/ExecutableSpecifications.jl?branch=master)

BDD is an acronym for _Behaviour Driven Development_. It is a process for creating and verifying
requirements, written in such a way that they can be executed as code. This package aims to be a
tool for executing such requirements, and creating reports.

This package is in the early stages of development, and has only minimal functionality.

# Usage
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
using ExecutableSpecifications
using CoffeeMachine

hascoffee(cup::Cup) = cup[:coffee] > 0.0

@given "that there is a cup in the coffee machine" begin
    cup = Cup()
    machine = Machine()

    cupisinthemachine(machine, cup)

    context[:cup] = cup
    context[:machine] = machine
end

@when "the \"Coffee\" button is pressed" begin
    machine = context[:machine]
    coffeewaspressed(machine)
end

@then "the cup is filled with coffee" begin
    cup = context[:cup]
    @expect hascoffee(cup)
end
```

Feature files have extension `.feature`, and are stored in the `features` directory (see
"Current state" for current limitations), and step definitions (the executable code) have the
extension `.jl` and are stored in `features/steps`.

# Example project
The project [CoffeeMachine.jl](https://github.com/erikedin/CoffeeMachine.jl) is an example of how to
use ExecutableSpecifications.jl.

# Running
Run the command line tool `runspec.jl` from the directory containing the `features` directory, or
from the Julia REPL with

```julia
julia> using ExecutableSpecifications
julia> runspec()
```

See "Current state" for limitations.

# Current state
The package has minimal functionality, but is under active development.

These are some current limitations and missing features, that will be lifted as development progresses:

- [ ] Presenting the results of scenarios is very rudimentary.
- [ ] Step definition variables do not yet have type information.
- [ ] Gherkin Rules support

## Completed

- [x] Reads feature files from anywhere under `features`.
- [x] Reads step files from anywhere under `features/steps`.
- [x] Variables in step definition strings.


# License
ExecutableSpecifications.jl is licensed under the Apache License version 2.0.
