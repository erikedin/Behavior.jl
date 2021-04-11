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
4. Ensure that the BDD requirements are run as part of the tests
5. Write Gherkin features
6. Implement the steps definitions

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
```
julia> ]
(@v1.6) pkg> activate CoffeeMachine
  Activating environment at `~/.julia/dev/CoffeeMachine/Project.toml`

(CoffeeMachine) pkg>
```
To add ExecutableSpecifications as a local development dependency, run
```
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