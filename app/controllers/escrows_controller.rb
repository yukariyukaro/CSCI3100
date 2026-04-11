class EscrowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_escrow, only: %i[confirm cancel]

  def confirm
    return redirect_to listing_path(@escrow.listing), alert: "Unauthorized" unless current_user.id == @escrow.seller_id

    unless @escrow.deposited?
      return redirect_to listing_path(@escrow.listing), alert: "Escrow is not ready for confirmation"
    end

    @escrow.complete_transaction!
    redirect_to listing_path(@escrow.listing), notice: "Transaction complete, funds released"
  end

  def cancel
    if current_user.id == @escrow.buyer_id
      @escrow.cancel_by_buyer!
      redirect_to listing_path(@escrow.listing), notice: "Transaction cancelled, deposit forfeited as penalty"
    elsif current_user.id == @escrow.seller_id
      stripe_service = Payments::StripePaymentService.new(current_user)
      stripe_service.refund_payment(@escrow.stripe_payment_intent_id) if @escrow.stripe_payment_intent_id.present?

      @escrow.cancel_by_seller_with_refund!
      redirect_to listing_path(@escrow.listing), notice: "Seller cancelled transaction, deposit refunded"
    else
      redirect_to listing_path(@escrow.listing), alert: "Unauthorized"
    end
  rescue Stripe::StripeError => e
    redirect_to listing_path(@escrow.listing), alert: e.message
  end

  private

  def set_escrow
    @escrow = Escrow.find(params[:id])
  end
end
