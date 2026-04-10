class ReleaseEscrowJob < ApplicationJob
  queue_as :default

  def perform(listing_id)
    # Mock logic to process deposit release for a specific listing
    # In a real app, this would interface with a payment gateway like Stripe
    listing = Listing.find_by(id: listing_id)

    if listing
      Rails.logger.info "Escrow Service: Releasing deposit for Listing ##{listing.id} (#{listing.title})"
    else
      Rails.logger.error "Escrow Service: Listing ##{listing_id} not found."
    end
  end
end
