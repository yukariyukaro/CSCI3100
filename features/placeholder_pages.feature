Feature: Placeholder pages
  Scenario Outline: Visit each module placeholder page
    Given I visit placeholder page "<path>"
    Then I should see placeholder text "<text>"

    Examples:
      | path          | text                         |
      | /test-default/products     | 全部商品             |
      | /test-default/conversations | Login               |
      | /test-default/payments     | Login                |
      | /test-default/listings     | Login                |
      | /sessions/new | Login                        |
      | /users/new    | Sign Up                      |
