class ListingMaintenanceJob < ApplicationJob
  queue_as :default

  def perform
    # RuboCop optimized the query to use the "Range" syntax (..30.days.ago)
    expired_products = Product.where(sale_status: "active")
                              .where(created_at: ..30.days.ago)

    # We use update_all for database performance (single SQL query).
    # We disable the RuboCop warning explicitly to show we know what we are doing.
    # rubocop:disable Rails/SkipsModelValidations
    count = expired_products.update_all(sale_status: "archived")
    # rubocop:enable Rails/SkipsModelValidations

    Rails.logger.info "ListingMaintenanceJob: Archived #{count} expired listings."
  end
end
