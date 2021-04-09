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
To create a new package `ExamplePackage`, first enter the Pkg mode by pressing
the `]` key.
```julia-repl
julia> ]
# The Julia REPL prompt changes to
(@v1.6) pkg> 
```
Create the package by running
```julia-repl
(@v1.6) pkg> generate ExamplePackage
  Generating  project ExamplePackage:
    ExamplePackage/Project.toml
    ExamplePackage/src/ExamplePackage.jl

(@v1.6) pkg> 
```
You now have a brand new package in `~/.julia/dev/ExamplePackage`.

# Step 2: Add some code
Open the file `~/.julia/dev/ExamplePackage/src/ExamplePackage.jl` and add the following
code inside the `ExamplePackage` module.
```julia
```