class PaymentSettlement
  def self.call(payment, provider_amount_cents:)
    new(payment, provider_amount_cents: provider_amount_cents).call
  end

  def initialize(payment, provider_amount_cents:)
    @payment = payment
    @provider_amount_cents = provider_amount_cents.to_i
  end

  def call
    return true if @payment.succeeded?

    unless amount_matches?
      mark_manual_intervention!("amount_mismatch expected=#{expected_cents} got=#{@provider_amount_cents}")
      return false
    end

    settle_with_lock
    @payment.reload.succeeded?
  rescue StandardError => e
    @payment.update!(status: :failed, error_details: "system_error #{e.class}: #{e.message}")
    raise
  end

  private

  def expected_cents
    (@payment.amount * 100).to_i
  end

  def amount_matches?
    expected_cents == @provider_amount_cents
  end

  def mark_manual_intervention!(details)
    @payment.update!(status: :manual_intervention_required, error_details: details)
  end

  def settle_with_lock
    Payment.transaction do
      @payment.product_transaction.with_lock do
        settle_in_lock
      end
    end
  end

  def settle_in_lock
    tx = @payment.product_transaction
    product = tx.product

    return mark_manual_intervention!("transaction_not_in_progress") unless tx.in_progress?
    return mark_manual_intervention!("product_not_pending") unless product.pending?

    mark_succeeded!(tx, product)
  end

  def mark_succeeded!(transaction, product)
    @payment.update!(status: :succeeded)
    transaction.update!(status: :completed)
    product.update!(sale_status: :sold)
  end
end
