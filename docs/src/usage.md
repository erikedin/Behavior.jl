# Usage

## Package layout
A Julia package commonly has the following files and directories:
```
ExamplePackage/
├── Manifest.toml
├── Project.toml
├── src
│   └── ExamplePackage.jl
└── test
    └── runtests.jl
```
To use Behavior.jl, add inside the package
- a directory `features`

    This directory will contain the Gherkin feature files.

- a directory `features/steps`

    This directory will contain the code that runs the actual
    test steps.

```
ExamplePackage/
├── features
│   ├── Example.feature
│   └── steps
│       └── ExampleSteps.jl
├── Manifest.toml
├── Project.toml
├── src
│   └── ExamplePackage.jl
└── test
    └── runtests.jl
```
Above you will see a single Gherkin feature file `features/Example.feature` and a single
step definition file `features/steps/ExampleSteps.jl`.

### Test organization
Behavior searches for both feature files and step files recursively. You may
place them in any subdirectory structure that you like. For instance,
```
ExamplePackage/
├── features
│   ├── steps
│   │   ├── ExampleSteps.jl
│   │   └── substeps
│   │       └── MoreSteps.jl
│   ├── subfeature1
│   │   └── Example.feature
│   └── subfeature2
│       └── Other.feature
├── Manifest.toml
├── Project.toml
├── src
│   └── ExamplePackage.jl
└── test
    └── runtests.jl
```

## Making assertions
There are currently two ways of making assertions in a step:

- `@expect <expression>`

  Checks that some boolean expression is true, and fails if it is not.

- `@fail <string>`

  Unconditionally fails a step, with an explanatory string.

Both these macros are exported from the `Behavior` module.
The `@expect` macro should be the primary method used for testing the actual
vs. expected values of your code. The `@fail` macro can be used when the
`@expect` macro is not appropriate, or for checking preconditions in the tests.

Examples:
```julia
using Behavior

@then("one plus one equals two") do context
    @expect 1+1 == 2
end
```

```julia
using Behavior

@given("some precondition") do context
    if !someprecondition()
        # This may not be part of the test, but a precondition to performing the
        # actual test you want.
        @fail "The tests required this particular precondition to be fulfilled"
    end
end
```

## Parameters
NOTE: This is a work in progress, and will see improvement.

A step in Gherkin is matched against step definitions in Julia code. These step definitions
may have parameters, which match against many values. For instance, the Gherkin
```Gherkin
Feature: Demonstrating parameters

  Scenario: Value forty-two
      Given some value 42

  Scenario: Value seventeen
      Given some value 17
```
we have two steps. Both of these steps will match the step definition
```julia
using Behavior

@given("value {String}") do context, value
    @expect value in ["42", "17"]
end
```
The step definition above has a parameter `{String}`, which matches any string following the
text `value `. The additional argument `value` in the do-block will have the value `"42"` in the
first scenario above, and `"17"` in the second.

In the parameter above we specify the type `String`. One can also use an empty
parameter `{}` which is an alias for `{String}`. The type of the argument `value` will naturally
be `String`.

One can have several parameters in the step definition. For instance, the step definition
```julia
using Behavior

@given("{} {}") do context, key, value
    @expect key == "value"
    @expect value in ["42", "17"]
end
```
This step definition will also match the above `Given` step, and the first argument `key` will
have the value `"value"` in both the scenarios.

Future work: In the near future, other types will be supported, such as `Int` and `Float`.

### Obsolete
Earlier, parameters were accessible in an object `args` that was provided to all step
implementations, like so
```julia
@given("value {foo}") do context
    @expect args[:foo] in ["42", "17"]
end
```
This is no longer supported, and the `args` variable is no longer present.

## Data tables
Gherkin supports tabular data associated with each step. For instance, the scenario
```Gherkin
Feature: Demonstrating data tables

    Scenario: Has a table
        Given some users
            | user id | name                |
            | 17      | Henry Case          |
            | 42      | Ainsley Lowbeer     |
            | 59      | Chevette Washington |
         When a search for "Henry Case" is made
         Then user id 17 is found
```
The `Given` step above has a data table associated with it. To access the data table
in a step definition, use the `datatable` field on the `context` object:
```julia
using Behavior

@given("some users") do context
    users = context.datatable
    println(users[1]) # Prints ["user id", "name"]
    println(users[2]) # Prints ["17", "Henry Case"]
    println(users[3]) # Prints ["42", "Ainsley Lowbeer"]
    println(users[4]) # Prints ["59", "Chevette Washington"]
end
```

## Strictness of Gherkin syntax
There are some ways to configure how strict we wish the Gherkin parser to be,
when reading a feature file. For instance, Behavior by default
requires you to only have steps in the order `Given-When-Then`. It fails if it finds,
for instance, a `Given` step after a `When` step in a Scenario. This reflects the
intended use of these steps, but may not be to everyones liking. Therefore, we can
control the strictness of the parser and allow such steps.

```Gherkin
Feature: Demonstrating step order

  Scenario: This scenario requires a more lenient parser
      Given some precondition
       When some action
       Then some postcondition
      Given some other precondition
       When some other action
       Then some other postcondition
```
The above feature file will by default fail, as the steps are not strictly in the
order `Given-When-Then`. The error message will look something like

```
ERROR: ./features/DemonstratingStepOrder.feature:7
      Line:     Given some other precondition
    Reason: bad_step_order
  Expected: NotGiven
    Actual: Given
```

To allow this, create a `Behavior.Gherkin.ParseOptions`
struct, with the keyword `allow_any_step_order = true`.

```julia-repl
julia> using Behavior
julia> using Behavior.Gherkin

julia> p = ParseOptions(allow_any_step_order = true)

julia> runspec(parseoptions=p)
```

Note that at the time of writing, the step order is the only option available for
configuration Gherkin parsing.

## Step implementation suggestions
Behavior can find scenario steps that do not have a corresponding
step implementation, and suggest one. For instance, if you have the feature

```Gherkin
# features/SomeFeature.feature
Feature: Suggestions example

    Scenario: Some scenario
        Given an existing step
         When a step is missing
```

and the step implementation

```julia
# features/steps/somesteps.jl
using Behavior

@given("an existing step") do context
    # Some  test
end
```

then we can see that the step `When a step is missing` does not have a corresponding
step implementation, like the `Given` step does. To get a suggestion for missing step
implementations in a given feature file, you can run

```julia-repl
julia> using Behavior

julia> suggestmissingsteps("features/SomeFeature.feature", "features/steps")
using Behavior

@when("a step is missing") do context
    @fail "Implement me"
end
```

In the code above, we provide `suggestmissingsteps` with a feature file path, and the path
where the step implementations are found. It will find that then `When` step above is missing
and provide you with a sample step implementation. The sample will always initially fail, using
the `@fail` macro, so that it is not accidentally left unimplemented.

Note that `suggestmissingsteps` can also take a `Behavior.Gherkin.ParseOptions` as an optional argument,
which allows you to configure how strict or lenient the parser should be when reading the feature file.

```julia-repl
julia> using Behavior
julia> using Behavior.Gherkin

julia> suggestmissingsteps("features/SomeFeature.feature", "features/steps",
                           parseoptions=ParseOptions(allow_any_step_order = true))
using Behavior

@when("a step is missing") do context
    @fail "Implement me"
end
```

Also note that currently, `suggestmissingsteps` takes only a single feature file. It would of course
be possible to have `suggestmissingsteps` find _all_ feature files in the project, but this could
potentially list too many missing steps to be of use.

### Known limitations
The suggestion method above does not currently generate any step implementations with variables.
This is because the variables are undergoing changes at the time of writing, so generating such
implementations would not be stable for the user.

### Caution
While it's tempting to use this as a means of automatically generating all missing step implementations,
it's important to note that Behavior cannot know how to organize the step implementations.
Oftentimes, many feature files will share common step implementations, so there will not be a
one-to-one correspondence between feature files and the step implementation files. Furthermore,
step implementations with variables will often match many steps for different values of the variables,
but the suggestion method will not be able to determine which steps you want to use variables for.
As an example, in the below feature file, it's quite obvious to a user that a variable step implementation
can be used to match all `Given some value {Int}`, but the suggestion method will not be able to detect this.

```Gherkin
Feature: Demonstrate suggestion limitations

    Scenario: Some scenario
        Given some value 17

    Scenario: Other scenario
        Given some value 42
```

## Selecting scenarios by tags
WARNING: At the time of writing the only supported way of selecting tags is a single tag or a
comma-separated list of tags, with an optional "not" expression:
- `@tag`,
- `@tag,@othertag,@thirdtag` matches any of the tags
- `not @tag`
- `not @tag,@othertag` will not match either `@tag` or `@othertag`

The tag selection is a work in progress.

You can select which scenarios to run using the tags specified in the Gherkin files. For example, a feature file can look like this
```Gherkin
@foo
Feature: Describing tags

    @bar @baz
    Scenario: Some scenario
        Given some step

    @ignore
    Scenario: Ignore this scenario
        Given some step
```
Here we have applied the tag `@foo` to the entire feature file. That is, the `@foo` tag is inherited by all scenarios in the feature file.
One scenario has the `@bar` and `@baz` tags, and another has the tag `@ignore`.

You can select to run only the scenarios marked with `@foo` by running
```julia-repl
julia> using Behavior
julia> runspec(tags = "@foo")
```
This will run both scenarios above, as they both inherit the `@foo` tag from the feature level.

You can run only the scenario marked with `@bar` by running
```julia-repl
julia> using Behavior
julia> runspec(tags = "@bar")
```
This will run only the first scenario `Scenario: Some scenario` above, as the second scenario does not have the `@bar` tag.

You can also choose to run scenarios that _do not_ have a given tag, such as `@ignore`.
```julia-repl
julia> using Behavior
julia> runspec(tags = "not @ignore")
```
This will also run only the first scenario, as it does not have the `@ignore` tag, but not the second.

If a feature does not have any matching scenarios, then that feature will be excluded from the results, as it had no bearing
on the result.

### Tag selection syntax
NOTE: The tag selection syntax is a work in progress.

- `@tag`

    Select scenarios with the tag `@tag`.

- `not @tag`

    Select scenarios that _do not_ have the tag `@tag`.

- `@tag,@othertag,@thirdtag`

    Select scenarios that have one or several of the tags `@tag`, `@othertag`, `@thirdtag`.

- `not @tag,@othertag,@thirdtag`

    Select scenarios that _do not_ have any of the tags `@tag`, `@othertag`, `@thirdtag`.

### Future syntax
In the future, you will be able to write a more complex expression using `and`, `or`, and parentheses, like
```
@foo and (not @ignore)
```
which will run all scenarios with the `@foo` tag that do not also have the `@ignore` tag.

## Before/after steps
You can create steps that execute before and after each scenario, for set up and tear down of test resources.
These must be placed in a file `features/environment.jl` (or some custom features directory you specify).
Note that this is _not_ the `features/steps` directory, where all step definitions are found, but in the
`features` directory.

The `@beforescenario` and `@afterscenario` definitions run before and after each scenario.

```julia
@beforescenario() do context, scenario
    # Some code here
end

@afterscenario() do context, scenario
    # Some code here
end
```

The intention is that one place test resources in the `context` object. This is the same object that
the scenario steps will receive as their `context` parameter, so any modifications to it will be
visible in the scenario steps.
The `scenario` parameter allows one to see which scenario is being executed, so test resources can
customized for each scenario.