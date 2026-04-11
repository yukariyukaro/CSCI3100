# rubocop:disable Metrics/ClassLength
class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: %i[show fake]
  before_action :set_product_transaction, only: %i[create_transaction]

  def index
    @payments = current_user.payments.includes(escrow: :listing).order(created_at: :desc)
  end

  def show
    return if @payment.user_id == current_user.id

    redirect_to payments_path, alert: t("payments.errors.unauthorized")
  end

  def new
    return redirect_to(listings_path, alert: t("payments.errors.listing_not_found")) if set_listing.blank?
    return redirect_to(listing_path(@listing), alert: t("payments.errors.own_listing")) if buying_own_listing?

    build_deposit_context
    create_deposit_intent
  end

  def create
    return unless prepare_create_request

    handle_payment_result(@payment_intent_id)
  rescue Stripe::StripeError => e
    redirect_to new_listing_payment_path(@listing), alert: e.message
  rescue ActiveRecord::RecordNotFound
    redirect_to listings_path, alert: t("payments.errors.escrow_not_found")
  end

  def create_transaction
    provider = Payments::ProviderFactory.instance
    @payment = Payment.create!(
      product_transaction: @product_transaction,
      amount: @product_transaction.product.price,
      provider: provider.name,
      status: :pending
    )

    checkout = provider.create_checkout(payment: @payment)
    @payment.update!(provider_reference: checkout[:provider_reference], callback_token: checkout[:callback_token])

    redirect_to checkout[:redirect_url]
  end

  def fake
    head :forbidden if params[:token].present? && params[:token] != @payment.callback_token
  end

  def webhook
    provider = Payments::ProviderFactory.instance
    payload = provider.verify_webhook(request)
    payment = Payment.find_by(provider_reference: payload.fetch("provider_reference"))
    return head :not_found if payment.blank?

    if payload.fetch("outcome", "succeeded") == "succeeded"
      PaymentSettlement.call(payment, provider_amount: payload.fetch("amount"))
    else
      payment.update!(status: :failed, error_details: "user_cancelled")
    end

    head :ok
  rescue KeyError
    head :bad_request
  end

  private

  def set_payment
    @payment = Payment.includes(escrow: :listing).find(params[:id])
  end

  def set_product_transaction
    @product_transaction = Transaction.includes(:product).find(params[:id])
  end

  def set_listing
    @listing = find_listing
  end

  def find_listing
    listing_id = params[:listing_id] || params.dig(:payment, :listing_id)
    return if listing_id.blank?

    Listing.find_by(id: listing_id)
  end

  def buying_own_listing?
    @listing.user_id == current_user.id
  end

  def build_deposit_context
    @escrow = Escrow.find_or_create_for!(listing: @listing, buyer: current_user)
    @payment = current_user.payments.new(
      escrow: @escrow,
      transaction_type: :deposit,
      amount: @escrow.amount,
      status: :pending
    )
  end

  # rubocop:disable Metrics/MethodLength
  def create_deposit_intent
    result = Payments::StripePaymentService.new(current_user).create_deposit_payment(
      amount: @escrow.amount,
      escrow: @escrow
    )

    if result[:success]
      @client_secret = result[:client_secret]
      @payment_intent_id = result[:payment_intent_id]
      @stripe_publishable_key = ENV.fetch("STRIPE_PUBLISHABLE_KEY", "")
    else
      redirect_to listing_path(@listing), alert: result[:error]
    end
  end
  # rubocop:enable Metrics/MethodLength

  def load_and_validate_escrow
    @escrow = Escrow.find(params[:escrow_id])
    @escrow if @escrow.buyer_id == current_user.id && @escrow.listing_id == @listing.id
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def prepare_create_request
    return redirect_to(listings_path, alert: t("payments.errors.listing_not_found")) if set_listing.blank?

    if load_and_validate_escrow.blank?
      return redirect_to(listing_path(@listing),
                         alert: t("payments.errors.unauthorized"))
    end

    @payment_intent_id = params[:payment_intent_id].to_s
    if @payment_intent_id.blank?
      return redirect_to(new_listing_payment_path(@listing),
                         alert: t("payments.errors.missing_payment_intent"))
    end

    true
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def handle_payment_result(payment_intent_id)
    payment_intent = Payments::StripePaymentService.new(current_user).retrieve_payment_intent(payment_intent_id)
    return handle_successful_payment(payment_intent_id) if successful_status?(payment_intent.status)

    handle_failed_payment(payment_intent_id)
  end

  def successful_status?(status)
    %w[succeeded processing requires_capture].include?(status)
  end

  def handle_successful_payment(payment_intent_id)
    persist_successful_payment!(payment_intent_id)
    @escrow.confirm_deposit_paid!(payment_intent_id) unless @escrow.deposited? || @escrow.completed?

    redirect_to payment_path(@payment), notice: t("payments.notices.deposit_frozen")
  end

  def persist_successful_payment!(payment_intent_id)
    @payment = Payment.find_or_initialize_by(stripe_payment_intent_id: payment_intent_id)
    @payment.assign_attributes(user: current_user, escrow: @escrow, provider: "escrow",
                               transaction_type: :deposit, amount: @escrow.amount,
                               status: :succeeded)
    @payment.save!
  end

  def handle_failed_payment(payment_intent_id)
    Payment.create!(
      user: current_user,
      escrow: @escrow,
      provider: "escrow",
      transaction_type: :deposit,
      amount: @escrow.amount,
      stripe_payment_intent_id: payment_intent_id,
      status: :failed
    )

    redirect_to new_listing_payment_path(@listing), alert: t("payments.errors.not_completed")
  end
end
# rubocop:enable Metrics/ClassLength
