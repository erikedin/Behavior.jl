Feature: This is a feature file

    Scenario: Steps are successful if they are empty
        Given some precondition which does nothing
         When we perform a no-op step
         Then the scenario as a whole succeeds

    Scenario: A step must have exactly one matching step definition
         When a step has more than one matching step definition
         Then this step is skipped

    Scenario Outline: This outline has two examples
         When foo is set to value <foo>
         Then foo is <comparison> than zero

        Examples:
            | foo | comparison |
            | 42  | greater    |
            | -17 | less       |

     Scenario: Doc strings are multi-line blocks of text
          When we need multiple lines of text
               """
               This is line 1.
               This is line 2.
               """
          Then we can use doc strings like this
               """
               And like
               this.
               """