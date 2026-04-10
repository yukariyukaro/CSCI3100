class PaymentSettlement
  def self.call(payment, provider_amount:)
    new(payment, provider_amount: provider_amount).call
  end

  def initialize(payment, provider_amount:)
    @payment = payment
    @provider_amount = BigDecimal(provider_amount.to_s)
  end

  def call
    return true if @payment.succeeded?

    unless amount_matches?
      mark_manual_intervention!("amount_mismatch expected=#{@payment.amount} got=#{@provider_amount}")
      return false
    end

    settle_with_lock
    @payment.reload.succeeded?
  rescue StandardError => e
    @payment.update!(status: :failed, error_details: "system_error #{e.class}: #{e.message}")
    raise
  end

  private

  def amount_matches?
    @payment.amount == @provider_amount
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
