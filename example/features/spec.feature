Feature: This is an example feature to show how ExecutableSpecifications.jl can be used.
    It does not test any other code, but uses test assertions to show what failures and successes
    look like.
    The tests will not all succeed, as some are meant to show what failures look like.

    Scenario: Using context to share variables
        Given that the context variable :x has value 1
         When the context variable :x is compared with 1
         Then the comparison is true

    Scenario: If a step fails, then the subsequent steps are skipped
         When this step fails
         Then this step is skipped

    Scenario: Unknown exceptions
         When this step throws an exception, the result is "Unknown exception"
         Then this step is skipped

    Scenario: Steps that have no definitions
         Given a step that has no corresponding step definition in steps/spec.jl
          When it is executed
          Then it fails with error "No matching step"