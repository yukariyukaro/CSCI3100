Feature: Authentication
  Scenario: User signs up, logs in, and logs out
    Given I am on the sign up page
    When I sign up with valid information
    Then I should see authentication success message
    When I log out
    Then I should see logout success message
    When I go to the login page
    And I log in with valid credentials
    Then I should see authentication success message
