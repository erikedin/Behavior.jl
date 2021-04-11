# ExecutableSpecifications Tutorial
This is a tutorial style introduction to how ExecutableSpecifications.jl works.
It is not intended as a complete introduction to Behavior Driven Development, but
rather an introduction to how to start with this package.

This tutorial assumes that you have Julia 1.0 or later installed. It also assumes
you're using Linux, or something similar, but the instructions can be adapted to
Windows.

Here is an overview of the steps we'll take:

1. Create a new package
2. Add some code to test
3. Add ExecutableSpecifications.jl as a dependency
4. Write a Gherkin feature
5. Implement the steps in the feature
6. Test the Gherkin feature
7. Add more BDD scenarios to the feature

If you have an existing package you wish to use, skip to step 3.

# Step 1: Create a new package
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

# Step 2: Add some code
Open the file `~/.julia/dev/CoffeeMachine/src/CoffeeMachine.jl` add code so that
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

# Step 3: Add ExecutableSpecifications as a dependency
NOTE: ExecutableSpecifications is not yet registered as a package, therefore
this tutorial will manually clone the repository from GitHub and add it as a
local development dependency.

In a terminal in `~/.julia/dev`, run
```bash
$ git clone https://github.com/erikedin/ExecutableSpecifications.jl ExecutableSpecifications
```
Note that we're cloning it into a repo with the `.jl` prefix, for consistency with the newly generated package.

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
To add ExecutableSpecifications as a local development dependency, run
```julia-repl
(CoffeeMachine) pkg> dev ExecutableSpecifications
[ Info: Resolving package identifier `ExecutableSpecifications` as a directory at `~/.julia/dev/ExecutableSpecifications`.
Path `ExecutableSpecifications` exists and looks like the correct package. Using existing path.
   Resolving package versions...
    Updating `~/.julia/dev/CoffeeMachine/Project.toml`
  [7a129280] + ExecutableSpecifications v0.1.0 `../ExecutableSpecifications`
    Updating `~/.julia/dev/CoffeeMachine/Manifest.toml`
  [7a129280] + ExecutableSpecifications v0.1.0 `../ExecutableSpecifications`
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
`@test` macro in the `CoffeeMachine/test/runtests.jl` test file later one.
```julia-repl
(CoffeeMachine) pkg> add Test
[ .. output not show for brevity .. ]
```

# Step 4: Write a Gherkin feature
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

# Step 5: Implement the steps in the feature
Create a directory `CoffeeMachine/features/steps`.
```bash
$ cd ~/.julia/dev/CoffeeMachine
$ mkdir -p features/steps
```
Add a file `CoffeeMachine/features/steps/makingcoffee.jl`:
```julia
using ExecutableSpecifications
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
test, and the `ExecutableSpecifications` module, which provides the test functions.

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
This is how ExecutableSpecifications connects the steps in the Gherkin `.feature` file
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
step does not make any assumption above _what_ the return cup actually is. In some cases
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
`@expect` macro is provided by `ExecutableSpecifications`, and checks that the
provided expression is true. It is very similar to the `@test` macro in the standard
`Test` module.

If the above expression was false, say that the returned `Cup` struct had `0.0` in its
coffee field, then the `@expect` macro would record a failure, and `ExecutableSpecifications`
would show this step as failed.

# Step 6: Test the Gherkin feature
The above steps have created a Gherkin feature file, and a step implementation file,
but we need to tell `ExecutableSpecifications` to run them.

Julias standard location for tests is in the `test/runtests.jl` file. Add a file
`CoffeeMachine/test/runtests.jl`:
```julia
using ExecutableSpecifications
using CoffeeMachine
using Test

@test runspec(pkgdir(CoffeeMachine)
```
This code calls the `ExecutableSpecifications.runspec` function, which finds all the
feature files and step implementations, and runs all `Scenarios`.
For this example, if will find the `Scenario` "Making a regular coffee", and for each
`Given`/`When`/`Then` step, find the matching step implementation in `CoffeeMachine/features/steps/makingcoffee.jl`, and run it.

The argument `pkgdir(CofeeMachine)` simply passes `runspec` the path to the root of the
`CoffeeMachine` package. From there, it will find the `features` and `features/steps` paths.

Finally, the `@test` macro is used here to ensure that `runspec` returns true, which it does
when all tests pass. If any tests fail, then `runspec` returns false, and the `@test` macro
records a failure, so that Julia knows it failed. Without the `@test` macro here,
`ExecutableSpecifications` will still run all tests, and display them, but the standard
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
`ExecutableSpecifications` will by default print each `Feature`, `Scenario`, and step as they
are being executed, and show a final result of how many scenarios succeeded, and how many
failed as part of each `Feature`. Finally, it `SUCCESS` to indicate that no errors were
found.

## Optional: Introduce an error to see failures
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