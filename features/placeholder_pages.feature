Feature: Placeholder pages
  Scenario Outline: Visit each module placeholder page
    Given I visit placeholder page "<path>"
    Then I should see placeholder text "<text>"

    Examples:
      | path          | text                         |
      | /products     | 全部商品                     |
      | /chats        | Login                        |
      | /payments     | Login                        |
      | /listings     | Login                        |
      | /sessions/new | Login                        |
      | /users/new    | Sign Up                      |
