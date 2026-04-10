class ReleaseEscrowJob < ApplicationJob
  queue_as :default

  def perform(listing_id)
    listing = Listing.find_by(id: listing_id)
    if listing
      Rails.logger.info "Escrow Service: Releasing deposit for Listing ##{listing.id}"
    else
      Rails.logger.error "Escrow Service: Listing ##{listing_id} not found."
    end
  end
end
