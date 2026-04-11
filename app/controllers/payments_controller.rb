class PaymentsController < ApplicationController
<<<<<<< HEAD
  before_action :authenticate_user!
  before_action :set_payment, only: %i[show]

  def index
    @payments = current_user.payments.includes(escrow: :listing).order(created_at: :desc)
  end

  def show
    return if @payment.user_id == current_user.id

    redirect_to payments_path, alert: "Unauthorized"
  end

  def new
    @listing = find_listing
    return redirect_to(listings_path, alert: "Listing not found") if @listing.blank?

    if @listing.user_id == current_user.id
      return redirect_to(listing_path(@listing),
                         alert: "You cannot buy your own listing")
    end

    @escrow = Escrow.find_or_create_for!(listing: @listing, buyer: current_user)
    @payment = current_user.payments.new(
      escrow: @escrow,
      transaction_type: :deposit,
      amount: @escrow.amount,
      status: :pending
    )

    stripe_service = Payments::StripePaymentService.new(current_user)
    result = stripe_service.create_deposit_payment(amount: @escrow.amount, escrow: @escrow)

    if result[:success]
      @client_secret = result[:client_secret]
      @payment_intent_id = result[:payment_intent_id]
      @stripe_publishable_key = ENV.fetch("STRIPE_PUBLISHABLE_KEY", "")
    else
      redirect_to listing_path(@listing), alert: result[:error]
    end
  end

  def create
    @listing = find_listing
    return redirect_to(listings_path, alert: "Listing not found") if @listing.blank?

    @escrow = Escrow.find(params[:escrow_id])
    if @escrow.buyer_id != current_user.id || @escrow.listing_id != @listing.id
      return redirect_to(listing_path(@listing), alert: "Unauthorized")
    end

    payment_intent_id = params[:payment_intent_id].to_s
    return redirect_to(new_listing_payment_path(@listing), alert: "Missing payment intent") if payment_intent_id.blank?

    stripe_service = Payments::StripePaymentService.new(current_user)
    payment_intent = stripe_service.retrieve_payment_intent(payment_intent_id)

    if %w[succeeded processing requires_capture].include?(payment_intent.status)
      @payment = Payment.find_or_initialize_by(stripe_payment_intent_id: payment_intent_id)
      @payment.assign_attributes(
        user: current_user,
        escrow: @escrow,
        transaction_type: :deposit,
        amount: @escrow.amount,
        status: :succeeded
      )
      @payment.save!

      @escrow.confirm_deposit_paid!(payment_intent_id) unless @escrow.deposited? || @escrow.completed?

      redirect_to payment_path(@payment), notice: "Deposit frozen, awaiting seller confirmation"
    else
      Payment.create!(
        user: current_user,
        escrow: @escrow,
        transaction_type: :deposit,
        amount: @escrow.amount,
        stripe_payment_intent_id: payment_intent_id,
        status: :failed
      )

      redirect_to new_listing_payment_path(@listing), alert: "Payment not completed"
    end
  rescue Stripe::StripeError => e
    redirect_to new_listing_payment_path(@listing), alert: e.message
  rescue ActiveRecord::RecordNotFound
    redirect_to listings_path, alert: "Escrow not found"
=======
  before_action :authenticate_user!, except: %i[webhook]
  skip_forgery_protection only: %i[webhook]

  def index
    @payments = payment_scope.order(created_at: :desc)
  end

  def show
    @payment = payment_scope.find(params[:id])
  end

  def create
    transaction = Transaction.includes(:product).find(params[:transaction_id])
    return redirect_not_payable(transaction) unless payable_by_current_user?(transaction)

    payment = find_or_create_pending_payment(transaction)
    checkout = provider.create_checkout(payment: payment)
    payment.update!(provider_reference: checkout[:provider_reference], callback_token: checkout[:callback_token])
    redirect_to checkout[:redirect_url]
  end

  def fake
    @payment = Payment.includes(product_transaction: :product).find(params[:id])
    return head :forbidden unless @payment.provider == "fake"
    return head :forbidden unless @payment.product_transaction.buyer_id == current_user.id

    head :forbidden unless token_matches?(params[:token], @payment.callback_token)
  end

  def webhook
    payload = provider.verify_webhook(request)
    payment = payment_from_payload(payload)
    return head :forbidden unless webhook_authorized?(payment, payload)
    return webhook_cancel(payment) if webhook_cancelled?(payload)

    PaymentSettlement.call(payment, provider_amount: provider.extract_amount(payload))
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def resolve
    payment = Payment.includes(product_transaction: :product).find(params[:id])
    return head :forbidden unless resolvable_by_current_user?(payment)

    payment.update!(resolved_at: Time.current, resolved_by_id: current_user.id)
    redirect_to user_path(current_user), notice: t("payments.manual_intervention.resolved")
>>>>>>> main
  end

  private

<<<<<<< HEAD
  def set_payment
    @payment = Payment.includes(escrow: :listing).find(params[:id])
  end

  def find_listing
    listing_id = params[:listing_id] || params.dig(:payment, :listing_id)
    return if listing_id.blank?

    Listing.find_by(id: listing_id)
=======
  def payment_scope
    Payment.joins(:product_transaction)
           .where("transactions.buyer_id = :id OR transactions.seller_id = :id", id: current_user.id)
  end

  def provider
    @provider ||= Payments::ProviderFactory.instance
  end

  def payable_by_current_user?(transaction)
    transaction.in_progress? && transaction.product.pending? && transaction.buyer_id == current_user.id
  end

  def redirect_not_payable(transaction)
    redirect_to product_path(transaction.product), alert: t("payments.errors.not_payable")
  end

  def find_or_create_pending_payment(transaction)
    existing = transaction.payments.pending.where(provider: provider.name).order(created_at: :desc).first
    return existing if existing.present?

    transaction.payments.create!(
      amount: transaction.product.price,
      status: :pending,
      provider: provider.name,
      callback_token: SecureRandom.hex(16)
    )
  end

  def token_matches?(token, expected)
    return false if token.blank? || expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected.to_s)
  end

  def webhook_cancel(payment)
    payment.update!(status: :cancelled)
    head :ok
  end

  def payment_from_payload(payload)
    Payment.find_by!(provider: provider.name, provider_reference: provider.extract_reference(payload))
  end

  def webhook_authorized?(payment, payload)
    return true unless provider.name == "fake"

    token_matches?(payload["token"], payment.callback_token)
  end

  def webhook_cancelled?(payload)
    payload.fetch("outcome", "succeeded").to_s == "cancelled"
  end

  def resolvable_by_current_user?(payment)
    payment.manual_intervention_required? &&
      payment.resolved_at.blank? &&
      payment.product_transaction.seller_id == current_user.id
>>>>>>> main
  end
end
