class PaymentsController < ApplicationController
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
  end

  private

  def set_payment
    @payment = Payment.includes(escrow: :listing).find(params[:id])
  end

  def find_listing
    listing_id = params[:listing_id] || params.dig(:payment, :listing_id)
    return if listing_id.blank?

    Listing.find_by(id: listing_id)
  end
end
