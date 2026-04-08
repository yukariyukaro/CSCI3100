# filepath: features/user_profile.feature
Feature: User Profile Page
  As a CUHK Marketplace user
  I want to view and manage my profile page
  So that I can showcase my listings and track my transactions

  Background:
    Given a user "Alice" exists with email "alice@example.com" and password "password123"
    And a user "Bob" exists with email "bob@example.com" and password "password123"

  # ─── Profile visibility (public) ────────────────────────────────────────────

  Scenario: Visitor views a public user profile
    Given I am not logged in
    When I visit Alice's profile page
    Then I should see Alice's name "Alice"
    And I should see Alice's avatar or placeholder
    And I should see the "My Items" section

  Scenario: Profile page shows the user's active listings
    Given Alice has a product "iPhone 14" with description "Good condition" and status "active"
    And I am not logged in
    When I visit Alice's profile page
    Then I should see "iPhone 14" in the items list

  Scenario: Sold items are still visible on the profile
    Given Alice has a product "Old MacBook" with description "Used laptop" and status "sold"
    And I am not logged in
    When I visit Alice's profile page
    Then I should see "Old MacBook" in the items list

  # ─── Transaction history (private) ──────────────────────────────────────────

  Scenario: Visitor cannot see transaction history
    Given Alice has a completed transaction for product "iPad Pro" with Bob as buyer
    And I am not logged in
    When I visit Alice's profile page
    Then I should not see the transaction details
    And I should see a message to log in to view transactions

  Scenario: Owner can see their own transaction history
    Given Alice has a completed transaction for product "iPad Pro" with Bob as buyer
    And I am logged in as "alice@example.com" with password "password123"
    When I visit Alice's profile page
    Then I should see the "My Transactions" tab or section
    And I should see "iPad Pro" in the transactions list

  Scenario: Another logged-in user cannot see transaction history
    Given Alice has a completed transaction for product "iPad Pro" with Bob as buyer
    And I am logged in as "bob@example.com" with password "password123"
    When I visit Alice's profile page
    Then I should not see the transaction details
    And I should see a message to log in to view transactions

  # ─── Avatar upload ───────────────────────────────────────────────────────────

  Scenario: Owner can update their avatar
    Given I am logged in as "alice@example.com" with password "password123"
    When I visit Alice's profile page
    And I upload a valid avatar image
    Then I should see a success notice
    And I should be on Alice's profile page

  # ─── Stats ───────────────────────────────────────────────────────────────────

  Scenario: Profile displays sold count
    Given Alice has a completed transaction for product "iPhone 12" with Bob as buyer
    And I am not logged in
    When I visit Alice's profile page
    Then I should see the sold count "1"
