Feature: Placeholder pages
  Scenario Outline: Visit each module placeholder page
    Given I visit placeholder page "<path>"
    Then I should see placeholder text "<text>"

    Examples:
      | path          | text                         |
      | /products     | Products Placeholder         |
      | /chats        | Chats Placeholder            |
      | /payments     | Payments Placeholder         |
      | /listings     | Listings Placeholder         |
      | /sessions/new | Login Placeholder            |
      | /users        | Users Placeholder            |
