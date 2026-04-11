class EscrowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_escrow, only: %i[confirm cancel]

  def confirm
    return unauthorized_redirect unless seller_action?

    return not_ready_redirect unless @escrow.deposited?

    @escrow.complete_transaction!
    redirect_to listing_path(@escrow.listing), notice: t(".success")
  end

  def cancel
    return cancel_by_buyer if buyer_action?
    return cancel_by_seller if seller_action?

    unauthorized_redirect
  rescue Stripe::StripeError => e
    redirect_to listing_path(@escrow.listing), alert: e.message
  end

  private

  def set_escrow
    @escrow = Escrow.find(params[:id])
  end

  def buyer_action?
    current_user.id == @escrow.buyer_id
  end

  def seller_action?
    current_user.id == @escrow.seller_id
  end

  def cancel_by_buyer
    @escrow.cancel_by_buyer!
    redirect_to listing_path(@escrow.listing), notice: t("escrows.cancel.buyer_success")
  end

  def cancel_by_seller
    refund_for_seller_cancel
    @escrow.cancel_by_seller_with_refund!
    redirect_to listing_path(@escrow.listing), notice: t("escrows.cancel.seller_success")
  end

  def refund_for_seller_cancel
    return if @escrow.stripe_payment_intent_id.blank?

    Payments::StripePaymentService.new(current_user).refund_payment(@escrow.stripe_payment_intent_id)
  end

  def unauthorized_redirect
    redirect_to listing_path(@escrow.listing), alert: t("escrows.errors.unauthorized")
  end

  def not_ready_redirect
    redirect_to listing_path(@escrow.listing), alert: t("escrows.errors.not_ready_for_confirmation")
  end
end
