# Behavior.jl Documentation
BDD is an acronym for _Behaviour Driven Development_. It is a process for creating and verifying
requirements, written in such a way that they can be executed as code. This package aims to be a
tool for executing such requirements, and creating reports.

# Quickstart
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