# ExecutableSpecifications

[![Build Status](https://travis-ci.org/erikedin/ExecutableSpecifications.jl.svg?branch=master)](https://travis-ci.org/erikedin/ExecutableSpecifications.jl)
[![codecov.io](http://codecov.io/github/erikedin/ExecutableSpecifications.jl/coverage.svg?branch=master)](http://codecov.io/github/erikedin/ExecutableSpecifications.jl?branch=master)

BDD is an acronym for _Behaviour Driven Development_. It is a process for creating and verifying
requirements, written in such a way that they can be executed as code. This package aims to be a
tool for executing such requirements, and creating reports.

This package is in the early stages of development, and has only minimal functionality. It is not
ready for general use, but is under active development.

# Usage
Specifications are written in the Gherkin format, such as

```gherkin
Feature: Coffee machine

    Scenario: Coffee with milk
        Given that the machine has both coffee beans and milk
         When the "Coffee with milk" button is pressed
         Then both coffee and milk is dispensed into the cup
```

For each `Given`, `When`, and `Then` line, a corresponding method is written, which is executed when
that line is reached.

```julia
using ExecutableSpecifications: @given, @when, @then, @expect
using CoffeeMachine

@given "that the machine has both coffee beans and milk" begin
    cup = CoffeeCup()
    machine = CoffeeMachine(cup, coffeebeans=100, milk=10)
    context[:machine] = machine
    context[:cup] = cup
end

@when "the "Coffee with milk" button is pressed" begin
    machine = context[:machine]
    machine.pressedCoffeeWithMilk()
end

@then "both coffee and milk is dispensed into the cup" begin
    cup = context[:cup]
    @expect hascoffee(cup)
    @expect hasmilk(cup)
end
```

Feature files have extension `.feature`, and are stored in the `features` directory (see
"Current state" for current limitations), and step definitions (the executable code) have the
extension `.jl` and are stored in `feature/steps`.

# Running
Run the command line tool `runspec.jl` from the directory containing the `features` directory.
The current functionality is rudimentary, and is not yet appropriate for general use.

See "Current state" for limitations.

# Current state
The package has minimal functionality, but is under active development.

These are some current limitations, that will be lifted as development progresses:

- Only one feature file and one step file.

    Today only the feature file `features/spec.feature` and step file `feature/steps/steps.jl` are
    read. Going forward, all feature files and all step files will be read of course.

- Scenario Outlines are parsed, but cannot be executed.
- Presenting the results of scenarios is very rudimentary.
- No final pass/fail result is reported.

    This means it cannot yet be used as part of an automatic tests, as there's no way to check for
    success or failure.

- No setup or teardown functions.

In short, this package is not ready for general use.

# License
ExecutableSpecifications.jl is licensed under the Apache License version 2.0.
