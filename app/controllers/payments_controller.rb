class PaymentsController < ApplicationController
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
  end

  private

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
  end
end
