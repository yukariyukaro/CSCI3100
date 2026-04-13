Feature: Theme Toggle
  As a user of CUHK Marketplace
  I want to switch between light and dark mode
  So that I can read the interface comfortably in any lighting condition

  Scenario: Theme toggle button is present on the home page
    Given I visit the home page
    Then I should see the theme toggle button

  Scenario: Theme toggle button has correct Stimulus attributes
    Given I visit the home page
    Then the theme toggle button should have data-controller "theme"
    And the theme toggle button should have data-action "click->theme#toggle"

  Scenario: Theme toggle button is accessible
    Given I visit the home page
    Then the theme toggle button should have an aria-label "Toggle theme"

  Scenario: Theme toggle button contains both sun and moon icons
    Given I visit the home page
    Then I should see the sun icon in the theme toggle
    And I should see the moon icon in the theme toggle

  Scenario: Page body supports dark mode background
    Given I visit the home page
    Then the page body should have the class "bg-base-100"

  Scenario: Theme toggle is visible on the products page too
    Given I visit the products page
    Then I should see the theme toggle button

  Scenario: Theme toggle appears to the left of the user avatar when logged in
    Given a user "ThemeUser" exists with email "theme_user@example.com" and password "password123"
    And I am logged in as "theme_user@example.com" with password "password123"
    When I visit the home page
    Then the theme toggle button should appear before the user dropdown in the page
