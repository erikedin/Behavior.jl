# Usage

## Step implementation suggestions
ExecutableSpecifications can find scenario steps that do not have a corresponding
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
using ExecutableSpecifications

@given("an existing step") do context
    # Some  test
end
```

then we can see that the step `When a step is missing` does not have a corresponding
step implementation, like the `Given` step does. To get a suggestion for missing step
implementations in a given feature file, you can run

```julia-repl
julia> using ExecutableSpecifications: suggestmissingsteps, ParseOptions

julia> parseoptions = ParseOptions(allow_any_step_order=true)

julia> suggestmissingsteps("features/SomeFeature.feature", "features/steps", parseoptions=parseoptions)
using ExecutableSpecifications

@when("a step is missing") do context
    @fail "Implement me"
end
```

In the code above, we provide `suggestmissingsteps` with a feature file path, and the path
where the step implementations are found. It will find that then `When` step above is missing
and provide you with a sample step implementation.

Note that `suggestmissingsteps` can also optionally take a `ParseOptions` as an optional argument,
which allows you to configure how strict or lenient the parser should be when reading the feature file.

Also note that currently, `suggestmissingsteps` takes only a single feature file. It would of course
be possible to have `suggestmissingsteps` find _all_ feature files in the project, but this could
potentially list too many missing steps to be of use.

### Known limitations
The suggestion method above does not currently generate any step implementations with variables.
This is because the variables are undergoing changes at the time of writing, so generating such
implementations would not be stable for the user.

### Caution
While it's tempting to use this as a means of automatically generating all missing step implementations,
it's important to note that ExecutableSpecifications cannot know how to organize the step implementations.
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

## Tag selector
TODO: Once tag selectors can be used