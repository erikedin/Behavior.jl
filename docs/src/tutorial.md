# Tutorial
This is a tutorial style introduction to how Behavior.jl works.
It is not intended as a complete introduction to Behavior Driven Development, but
rather as an introduction to how to start with this package.

This tutorial assumes that you have Julia 1.0 or later installed. It also assumes
you're using Linux, or something similar, but the instructions can be adapted to
Windows.

Here is an overview of the steps we'll take:

1. Create a new package
2. Add some code to test
3. Add Behavior.jl as a dependency
4. Write a Gherkin feature
5. Implement the steps in the feature
6. Test the Gherkin feature
7. Add further scenarios
8. Scenario Outlines
9. Parameters

If you have an existing package you wish to use, skip to step 3, and mentally
replace the package name `CoffeeMachine` with your package name.

## Step 1: Create a new package
Go to a path where you want to create your new package, commonly
`~/.julia/dev`, and start Julia there.
```
$ cd ~/.julia/dev
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.0 (2021-03-24)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> 

```
To create a new package `CoffeeMachine`, first enter the Pkg mode by pressing
the `]` key.
```julia-repl
julia> ]
# The Julia REPL prompt changes to
(@v1.6) pkg> 
```
Create the package by running
```julia-repl
(@v1.6) pkg> generate CoffeeMachine
  Generating  project CoffeeMachine:
    CoffeeMachine/Project.toml
    CoffeeMachine/src/CoffeeMachine.jl

(@v1.6) pkg> 
```
You now have a brand new package in `~/.julia/dev/CoffeeMachine`.

## Step 2: Add some code
Open the file `~/.julia/dev/CoffeeMachine/src/CoffeeMachine.jl` and add code so that
the `CoffeeMachine` module looks like this (you can remove the default `greet` function):
```julia
module CoffeeMachine

export Machine, Cup, makecoffee!, fillwith!, readdisplay

mutable struct Machine
    coffee::Float64
    milk::Float64
    message::String

    Machine(; coffee=0.0, milk=0.0) = new(coffee, milk, "")
end

struct Cup
    coffee::Float64
    milk::Float64
end

function fillwith!(m::Machine; coffee=0.0, milk=0.0)
    m.coffee += coffee
    m.milk += milk
end

function makecoffee!(m::Machine; withmilk=false) :: Union{Cup, Nothing}
    if m.coffee <= 0.0
        display!(m, "Out of coffee")
        return nothing
    end

    if withmilk && m.milk <= 0.0
        display!(m, "Out of milk")
        return nothing
    end

    milkincup = if withmilk
        1.0
    else
        0.0
    end

    m.coffee -= 1.0
    m.milk -= milkincup

    display!(m, "Enjoy")

    Cup(1.0, milkincup)
end

readdisplay(m::Machine) = m.message
display!(m::Machine, msg::String) = m.message = msg

end # module
```
This is a model of a coffee machine, solely for demonstration purposes. It allows you to
make a cup of coffee, optionally with milk. It also has a display that shows messages to
the user.

In later steps, we'll create a Gherkin feature that exercises this code.

## Step 3: Add Behavior as a dependency
NOTE: Behavior is not yet registered as a package, therefore
this tutorial will manually clone the repository from GitHub and add it as a
local development dependency.

In a terminal in `~/.julia/dev`, run
```bash
$ git clone https://github.com/erikedin/Behavior.jl Behavior
```
Note that we're cloning it into a repo without the `.jl` prefix, for consistency with the newly generated package.

Start Julia in `~/.julia/dev` and activate the CoffeeMachine package, by
```
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.0 (2021-03-24)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia>
```
Go into the package mode and activate CoffeeMachine
```julia-repl
julia> ]
(@v1.6) pkg> activate CoffeeMachine
  Activating environment at `~/.julia/dev/CoffeeMachine/Project.toml`

(CoffeeMachine) pkg>
```
To add Behavior as a local development dependency, run
```julia-repl
(CoffeeMachine) pkg> dev Behavior
[ Info: Resolving package identifier `Behavior` as a directory at `~/.julia/dev/Behavior`.
Path `Behavior` exists and looks like the correct package. Using existing path.
   Resolving package versions...
    Updating `~/.julia/dev/CoffeeMachine/Project.toml`
  [7a129280] + Behavior v0.1.0 `../Behavior`
    Updating `~/.julia/dev/CoffeeMachine/Manifest.toml`
  [7a129280] + Behavior v0.1.0 `../Behavior`
  [c27321d9] + Glob v1.3.0
  [2a0f44e3] + Base64
  [b77e0a4c] + InteractiveUtils
  [56ddb016] + Logging
  [d6f4376e] + Markdown
  [9a3f8284] + Random
  [9e88b42a] + Serialization
  [8dfed614] + Test
```

We additionally require the standard `Test` module as a dependency, because we'll use the
`@test` macro in the `CoffeeMachine/test/runtests.jl` test file later on.
```julia-repl
(CoffeeMachine) pkg> add Test
[ .. output not shown for brevity .. ]
```

## Step 4: Write a Gherkin feature
Create a directory `CoffeeMachine/features`.
```bash
$ cd ~/.julia/dev/CoffeeMachine
$ mkdir features
```
Add the following Gherkin feature into the file `CoffeeMachine/features/MakingCoffee.feature`:
```Gherkin
Feature: Making Coffee

    Scenario: Making a regular coffee
        Given a machine filled with coffee beans
         When a user makes a cup of coffee
         Then the cup contains coffee
```
This file is a simple Gherkin file that contains a requirement that the `CoffeeMachine`
should fulfill.

The file starts by defining a `Feature`, with a short description of what this feature
is about.
A feature file contains one or more `Scenario`s, and each `Scenario` has steps on the form
`Given`, `When`, or `Then`.
In this example, there is one `Scenario`, with three steps.

The above requirement simply states that the machine should dispense coffee into the cup,
under the assumption that there's enough coffee in the machine.

To actually run these requirements as code, we need to add implementations for each step
above.

## Step 5: Implement the steps in the feature
Create a directory `CoffeeMachine/features/steps`.
```bash
$ cd ~/.julia/dev/CoffeeMachine
$ mkdir -p features/steps
```
Add a file `CoffeeMachine/features/steps/makingcoffee.jl`:
```julia
using Behavior
using CoffeeMachine

@given("a machine filled with coffee beans") do context
    context[:machine] = Machine(coffee=5.0)
end

@when("a user makes a cup of coffee") do context
    m = context[:machine]
    cup = makecoffee!(m)
    context[:cup] = cup
end

@then("the cup contains coffee") do context
    cup = context[:cup]

    @expect cup.coffee > 0.0
end
```
This file begins by `using` the `CoffeeMachine` module, which is the thing we wish to
test, and the `Behavior` module, which provides the test functions.

The first step implementation is
```julia
@given("a machine filled with coffee beans") do context
    context[:machine] = Machine(coffee=5.0)
end
```
This is a Julia implementation of the `Scenario` step
```Gherkin
Given a machine filled with coffee beans
```
Note that the string provided to the `@given` macro matches that of the `Given` step.
This is how Behavior connects the steps in the Gherkin `.feature` file
with actual code.

The `do context ... end` is the test function that will run for this step.

This snippet of code creates a coffee machine using the `Machine` constructor from the
`CoffeeMachine` module, and provides the coffee machine with 5.0 units of coffee.
It then stores this struct in the `context` dictionary, using the key `:machine`.
The `context` is a dictionary-like object that stores objects between steps. In this
case, the next step will fetch the `Machine` struct from the `context` and perform
operations on it.

The second step implementation is
```julia
@when("a user makes a cup of coffee") do context
    m = context[:machine]
    cup = makecoffee!(m)
    context[:cup] = cup
end
```
This corresponds to the `Scenario` step
```Gherkin
When a user makes a cup of coffee
```

This step retrieves the `Machine` struct from the `context`. The `Machine` struct
was created in the step before this one.
Then we call the `makecoffee!` function, provided by the `CoffeeMachine` module, on this machine.
We store the returned cup in the context, under the key `:cup`.

Note that each step ought to perform a single well-defined action. For instance, this
step does not make any assumption above _what_ the returned cup actually is. In some cases
it will be a `Cup` struct, and in some cases it will be a `Nothing`. This step does not
care about that, but leaves that to later steps.

The third and final step checks that the result is what we expect:
```julia
@then("the cup contains coffee") do context
    cup = context[:cup]

    @expect cup.coffee > 0.0
end
```
This step retrieves the cup, which was stored in the `context` by the previous step.
We use the `@expect` macro to check that the cup does indeed contain coffee. The
`@expect` macro is provided by `Behavior`, and checks that the
provided expression is true. It is very similar to the `@test` macro in the standard
`Test` module.

If the above expression was false, say that the returned `Cup` struct had `0.0` in its
coffee field, then the `@expect` macro would record a failure, and `Behavior`
would show this step as failed.

## Step 6: Test the Gherkin feature
The above steps have created a Gherkin feature file, and a step implementation file,
but we need to tell `Behavior` to run them.

Julias standard location for tests is in the `test/runtests.jl` file. Add a file
`CoffeeMachine/test/runtests.jl`:
```julia
using Behavior
using CoffeeMachine
using Test

@test runspec(pkgdir(CoffeeMachine)
```
This code calls the `Behavior.runspec` function, which finds all the
feature files and step implementations, and runs all `Scenarios`.
For this example, if will find the `Scenario` "Making a regular coffee", and for each
`Given`/`When`/`Then` step, find the matching step implementation in `CoffeeMachine/features/steps/makingcoffee.jl`, and run it.

The argument `pkgdir(CofeeMachine)` simply passes `runspec` the path to the root of the
`CoffeeMachine` package. From there, it will find the `features` and `features/steps` paths.

Finally, the `@test` macro is used here to ensure that `runspec` returns true, which it does
when all tests pass. If any tests fail, then `runspec` returns false, and the `@test` macro
records a failure, so that Julia knows it failed. Without the `@test` macro here,
`Behavior` will still run all tests, and display them, but the standard
Julia testrunner will not know that any tests failed.

To run the tests, enter the package mode for the `CoffeeMachine` package, and run the `test` command.
```julia
julia> ]
(CoffeeMachine) pkg> test
     Testing CoffeeMachine
     [ .. some Julia output, ignored for brevity .. ]
     Testing Running tests...

Feature: Making Coffee
  Scenario: Making a regular coffee
    Given a machine filled with coffee beans
     When a user makes a cup of coffee
     Then the cup contains coffee

                         | Success | Failure
  Feature: Making Coffee | 1       | 0


SUCCESS
     Testing CoffeeMachine tests passed
```
`Behavior` will by default print each `Feature`, `Scenario`, and step as they
are being executed, and show a final result of how many scenarios succeeded, and how many
failed as part of each `Feature`. Finally, it says `SUCCESS` to indicate that no errors were
found.

### Optional: Introduce an error to see failures
To see what failures look like, we can intentionally introduce an error into `CoffeeMachine`.

In the file `CoffeeMachine/src/CoffeeMachine.jl`, find the function
```julia
function makecoffee!(m::Machine; withmilk=false) :: Union{Cup, Nothing}
    if m.coffee <= 0.0
        display!(m, "Out of coffee")
        return nothing
    end

    if withmilk && m.milk <= 0.0
        display!(m, "Out of milk")
        return nothing
    end

    milkincup = if withmilk
        1.0
    else
        0.0
    end

    m.coffee -= 1.0
    m.milk -= milkincup

    display!(m, "Enjoy")

    Cup(1.0, milkincup)
end
```
At the end of this function, change that last line to
```julia
function makecoffee!(m::Machine; withmilk=false) :: Union{Cup, Nothing}
    .. keep the rest of the function as is

    Cup(0.0, milkincup)
end
```
This ensures that the cup will _not_ contain any coffee.

From the package mode in the `CoffeeMachine` package, run `test` again.
```julia-repl
(CoffeeMachine) pkg> test
     Testing CoffeeMachine
     [ .. output removed for brevity .. ]
     Testing Running tests...

Feature: Making Coffee
  Scenario: Making a regular coffee
    Given a machine filled with coffee beans
     When a user makes a cup of coffee
     Then the cup contains coffee

        FAILED: cup.coffee > 0.0


                         | Success | Failure
  Feature: Making Coffee | 0       | 1


FAILURE
Test Failed at /home/erik/.julia/dev/CoffeeMachine/test/runtests.jl:5
  Expression: runspec(pkgdir(CoffeeMachine))
ERROR: LoadError: There was an error during testing
in expression starting at /home/erik/.julia/dev/CoffeeMachine/test/runtests.jl:5
ERROR: Package CoffeeMachine errored during testing
```
You will see above that while the `Given` and `When` steps were successful, the
`Then` step failed, and it shows the expression that failed `cup.coffee > 0.0`.

Furthermore, the entire feature is marked as failed, and we see that `1` scenario
failed in that feature.

To continue, ensure that you undo the intentional error, so that the tests pass again.

## Step 7: Add further scenarios
Add the following `Scenario` to `CoffeeMachine/features/MakingCoffee.feature`:
```Gherkin
Scenario: Making coffee with milk
    Given a machine filled with coffee beans
      And that the machine also has milk
     When a user makes a cup of coffee with milk
     Then the cup contains coffee
      And the cup contains milk
```
Note that some of the steps are the same as the previous `Scenario`, while others
are new.

If you run the tests again, you will get a failure saying
```
Scenario: Making coffee with milk
  Given a machine filled with coffee beans
  Given that the machine also has milk

      No match for 'Given that the machine also has milk'
```
This error occurs because we haven't added any step definition for the step
`And that the machine also has milk` yet. The Gherking step type `And` means that
the step type will be whatever came before it, which is a `Given` in this situation.
So, add a step implementation in `CoffeeMachine/features/steps/makingcoffee.jl`:
```julia
@given("that the machine also has milk") do context
    m = context[:machine]
    fillwith!(m, milk=5.0)
end
```
This expects that a machine has already been constructed, and simply fills
it with milk.

Also add step implementations for the other new steps:
```julia
@when("a user makes a cup of coffee with milk") do context
    m = context[:machine]
    cup = makecoffee!(m, withmilk=true)
    context[:cup] = cup
end

@then("the cup contains milk") do context
    cup = context[:cup]

    @expect cup.milk > 0.0
end
```
The first one calls `makecoffee!`, but this time with the keyword argument
`withmilk=true`, indicating that we want milk in the coffee.

The second step definition checks that there is milk in the cup.

Runing the tests shows that both scenarios now pass.

```julia-repl
(CoffeeMachine) pkg> test
     Testing CoffeeMachine
     [ .. removed output for brevity .. ]
     Testing Running tests...

Feature: Making Coffee
  Scenario: Making a regular coffee
    Given a machine filled with coffee beans
     When a user makes a cup of coffee
     Then the cup contains coffee

  Scenario: Making coffee with milk
    Given a machine filled with coffee beans
    Given that the machine also has milk
     When a user makes a cup of coffee with milk
     Then the cup contains coffee
     Then the cup contains milk

                         | Success | Failure
  Feature: Making Coffee | 2       | 0


SUCCESS
     Testing CoffeeMachine tests passed
```

Note that step
```Gherkin
Then the cup contains coffee
```
is reused, as is the initial `Given` that constructs the coffee machine. It is
expected that many, if not most, step definitions will be shared by many scenarios.

## Step 8: Scenario Outlines
`Scenario Outline`s in Gherkin is a way to run one scenario for many similar values.
For instance, say that we want to test the machine's error messages when it is out
of an ingredient. We could write two different scenarios, one for when the machine is
out of coffee, and one for when it is out of milk.

```Gherkin
Feature: Displaying messages

    Scenario: Out of coffee
        Given a machine without coffee
         When a user makes a cup of coffee with milk
         Then the machine displays Out of coffee

    Scenario: Out of milk
        Given a machine without milk
         When a user makes a cup of coffee with milk
         Then the machine displays Out of milk
```
However, note that the two scenarios above are nearly identical, only differing
in specific values. The sequence of steps are the same, and the type of situation
tested is the same. The only differences are which ingredient is missing and which
error message we expect. This is a situation where you can use a single `Scenario Outline` to
express more than one `Scenario`.

Create a new feature file `CoffeeMachine/features/Display.feature`:
```Gherkin
Feature: Displaying messages

    Scenario Outline: Errors
        Given a machine without <ingredient>
         When a user makes a cup of coffee with milk
         Then the machine displays <message>

        Examples:
            | ingredient | message       |
            | coffee     | Out of coffee |
            | milk       | Out of milk   |
```
The above `Scenario Outline` looks like the above `Scenario`s, but introduces two placeholders,
`<ingredient>` and `<message>` instead of specific values. In the `Examples:` section we
have a table that lists which error message we expect for a given missing ingredient.
The first line in the table has the two placeholders `ingredient` and `message` as
column headers.

This `Scenario Outline` is exactly equivalent to the two `Scenario`s above. To run it,
create a new step definition file `CoffeeMachine/features/steps/display.jl`:
```julia
using Behavior
using CoffeeMachine

@given("a machine without coffee") do context
    context[:machine] = Machine(coffee=0.0, milk=5.0)
end

@given("a machine without milk") do context
    context[:machine] = Machine(coffee=5.0, milk=0.0)
end

@then("the machine displays Out of coffee") do context
    m = context[:machine]
    @expect readdisplay(m) == "Out of coffee"
end

@then("the machine displays Out of milk") do context
    m = context[:machine]
    @expect readdisplay(m) == "Out of milk"
end
```
You can run the tests to ensure that they pass.

## Step 9: Parameters
In the above step, we saw how `Scenario Outline`s can be utilized to reduce otherwise
repetitive `Scenario`s, and improve readability. In the step definition file above, also
note that we have two repetitive steps
```julia
@then("the machine displays Out of coffee") do context
    m = context[:machine]
    @expect readdisplay(m) == "Out of coffee"
end

@then("the machine displays Out of milk") do context
    m = context[:machine]
    @expect readdisplay(m) == "Out of milk"
end
```
These two steps check the same aspect of the coffee machine, but for two different values.
While `Scenario Outline`s can be used to reduce repetition in `.feature` files,
parameters can be used to reduce repetition in the step definition `.jl` files.

Both steps above can be reduced to a single step
```julia
@then("the machine displays {String}") do context, message
    m = context[:machine]
    @expect readdisplay(m) == message
end
```
There are two differences here:

1. The step string has a parameter `{String}` which matches any text.
2. The do-block function now takes two parameters, `context` and `message`.

The value of the `message` argument to the do-block is whatever text is matched by `{String}`.
So, for the first example above
```
Then the machine displays Out of coffee
```
this step will match the step definition `"the machine displays {String}"`, and the variable `message` will take on the value `Out of coffee`.

In this way, we can write a single step definition to match many `Scenario` steps.

Note that while the above example uses a `Scenario Outline` to demonstrate parameters in the
step definition `.jl` file, these are two separate concepts. A step definition with a parameter
like `{String}` can be used for `Scenario`s as well.