module PaymentsControllerHelpers
  private

  def payment_scope
    Payment.joins(:product_transaction)
           .where(transactions: { community_id: Current.community.id })
           .where("transactions.buyer_id = :id OR transactions.seller_id = :id", id: current_user.id)
  end

  def token_matches?(token, expected)
    return false if token.blank? || expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected.to_s)
  end
end
