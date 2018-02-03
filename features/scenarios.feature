Feature: Reading scenarios

    Scenario: Given statement
        Given a scenario
        """
        Scenario: This has a single given statement
            Given some precondition
        """
        When this scenario is read
        Then a given statement exists with value "some precondition"

    Scenario: When statement
        Given a scenario
        """
        Scenario: This has a single when statement
            When an action is performed
        """
        When this scenario is read
        Then a when statement exists with value "an action is performed"

    Scenario: Then statement
        Given a scenario
        """
        Scenario: This has a single then statement
            Then some condition holds
        """
        When this scenario is read
        Then a then statement exists with value "some condition holds"

    Scenario: Scenario description
        Given a scenario
        """
        Scenario: This is a description
            Given some precondition
        """
        When this scenario is read
        Then the scenario has the description "This is a description"
