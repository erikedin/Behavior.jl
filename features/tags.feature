Feature: Tags

    Scenario: Tags can be applied to scenarios
        Given a scenario
        """
        @tag1
        Scenario: Some description
            Given a precondition
        """
        When this scenario is read
        Then it has a tag "@tag1"

    Scenario: Tags can be applied to features
        Given a feature
        """
        @tag1
        Feature: Some feature
        """
        When this feature is read
        Then it has a tag "@tag1"

    Scenario: Feature tags are inherited by scenarios
        Given a feature
        """
        @tag1
        Feature: Some feature

            Scenario: Some scenario
                Given a precondition
        """
        When this feature is read
        Then the scenario "Some scenario" has tag "@tag1"

    Scenario: Multiple tags are separated by space
        Given a scenario
        """
        @tag1 @tag2 @tag3
        Scenario: A scenario with multiple tags
            Given a precondition
        """
        When this scenario is read
        Then it has tags "@tag1", "@tag2", and "@tag3"
