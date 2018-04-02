Feature: This is a feature file

    Scenario: Steps are successful if they are empty
        Given some precondition which does nothing
         When we perform a no-op step
         Then the scenario as a whole succeeds

    Scenario: A step must have exactly one matching step definition
         When a step has more than one matching step definition
         Then this step is skipped