# Usage

## Making assertions
There are currently two ways of making assertions in a step:

- `@expect <expression>`

  Checks that some boolean expression is true, and fails if it is not.

- `@fail <string>`

  Unconditionally fails a step, with an explanatory string.

Both these macros are exported from the `ExecutableSpecifications` module.
The `@expect` macro should be the primary method used for testing the actual
vs. expected values of your code. The `@fail` macro can be used when the
`@expect` macro is not appropriate, or for checking preconditions in the tests.

Examples:
```julia
using ExecutableSpecifications

@then("one plus one equals two") do context
    @expect 1+1 == 2
end
```

```julia
using ExecutableSpecifications

@given("some precondition") do context
    if !someprecondition()
        # This may not be part of the test, but a precondition to performing the
        # actual test you want.
        @fail "The tests required this particular precondition to be fulfilled"
    end
end
```

## Strictness of Gherkin syntax
There are some ways to configure how strict we wish the Gherkin parser to be,
when reading a feature file. For instance, ExecutableSpecifications by default
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

To allow this, create a `ExecutableSpecifications.Gherkin.ParseOptions`
struct, with the keyword `allow_any_step_order = true`.

```julia-repl
julia> using ExecutableSpecifications
julia> using ExecutableSpecifications.Gherkin

julia> p = ParseOptions(allow_any_step_order = true)

julia> runspec(parseoptions=p)
```

Note that at the time of writing, the step order is the only option available for
configuration Gherkin parsing.

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
julia> using ExecutableSpecifications

julia> suggestmissingsteps("features/SomeFeature.feature", "features/steps")
using ExecutableSpecifications

@when("a step is missing") do context
    @fail "Implement me"
end
```

In the code above, we provide `suggestmissingsteps` with a feature file path, and the path
where the step implementations are found. It will find that then `When` step above is missing
and provide you with a sample step implementation. The sample will always initially fail, using
the `@fail` macro, so that it is not accidentally left unimplemented.

Note that `suggestmissingsteps` can also take a `ExecutableSpecifications.Gherkin.ParseOptions` as an optional argument,
which allows you to configure how strict or lenient the parser should be when reading the feature file.

```julia-repl
julia> using ExecutableSpecifications
julia> using ExecutableSpecifications.Gherkin

julia> suggestmissingsteps("features/SomeFeature.feature", "features/steps",
                           parseoptions=ParseOptions(allow_any_step_order = true))
using ExecutableSpecifications

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