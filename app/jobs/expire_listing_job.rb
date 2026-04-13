class ExpireListingJob < ApplicationJob
  queue_as :default

  def perform
    # Find available listings created more than 30 days ago
    # Use find_each to iterate through records and update individually
    # to ensure model validations are respected.
    expired_listings = Listing.where(status: "available", created_at: ...30.days.ago)

    expired_listings.find_each do |listing|
      listing.update(status: "expired")
    end

    Rails.logger.info "Background Cleanup: Processed #{expired_listings.count} listings for expiration."
  end
end
