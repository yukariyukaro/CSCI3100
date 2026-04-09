Feature: Real-time Chat between buyer and seller
  As a logged-in buyer
  I want to send messages to a seller about a product
  So that we can negotiate and arrange the transaction

  Background:
    Given a user "Alice" exists with email "alice_chat@example.com" and password "password123"
    And a user "Bob" exists with email "bob_chat@example.com" and password "password123"
    And a chat product "iPhone 14" exists for seller "alice_chat@example.com"

  Scenario: Buyer can access chat from product page
    Given I am logged in as "bob_chat@example.com" with password "password123"
    When I visit the product page for "iPhone 14"
    Then I should see a "联系卖家" link

  Scenario: Buyer opens a conversation with the seller
    Given I am logged in as "bob_chat@example.com" with password "password123"
    When I visit the product page for "iPhone 14"
    And I click "联系卖家"
    Then I should be on a conversation page
    And I should see "iPhone 14"

  Scenario: Buyer can send a message in a conversation
    Given I am logged in as "bob_chat@example.com" with password "password123"
    And a conversation exists between Bob and Alice about "iPhone 14"
    When I visit that conversation
    And I fill in the message field with "Is this still available?"
    And I click "Send"
    Then I should see "Is this still available?" in the chat

  Scenario: Seller can see all their conversations
    Given I am logged in as "alice_chat@example.com" with password "password123"
    And a conversation exists between Bob and Alice about "iPhone 14"
    When I visit the conversations page
    Then I should see "Bob" in the conversation list

  Scenario: Non-participant cannot access a conversation
    Given a user "Charlie" exists with email "charlie_chat@example.com" and password "password123"
    And I am logged in as "charlie_chat@example.com" with password "password123"
    And a conversation exists between Bob and Alice about "iPhone 14"
    When I try to access that conversation directly
    Then I should be forbidden
