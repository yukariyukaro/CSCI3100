Feature: Placeholder pages
  Scenario Outline: Visit each module placeholder page
    Given I visit placeholder page "<path>"
    Then I should see placeholder text "<text>"

    Examples:
      | path          | text                         |
      | /products     | 全部商品                     |
      | /chats        | Chats Placeholder            |
      | /payments     | Payments Placeholder         |
      | /listings     | Listings Placeholder         |
      | /sessions/new | Login                        |
      | /users/new    | Sign Up                      |
