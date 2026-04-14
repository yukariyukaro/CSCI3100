namespace :consistency_check do
  task communities: :environment do
    errors = []

    users_missing = User.where(community_id: nil).count
    errors << "users missing community_id: #{users_missing}" if users_missing.positive?

    products_missing = Product.where(community_id: nil).count
    errors << "products missing community_id: #{products_missing}" if products_missing.positive?

    conv_missing = Conversation.where(community_id: nil).count
    errors << "conversations missing community_id: #{conv_missing}" if conv_missing.positive?

    tx_missing = Transaction.where(community_id: nil).count
    errors << "transactions missing community_id: #{tx_missing}" if tx_missing.positive?

    conv_mismatch = Conversation.joins(:product).where("conversations.community_id <> products.community_id").count
    errors << "conversations community_id mismatch with product: #{conv_mismatch}" if conv_mismatch.positive?

    tx_mismatch = Transaction.joins(:product).where("transactions.community_id <> products.community_id").count
    errors << "transactions community_id mismatch with product: #{tx_mismatch}" if tx_mismatch.positive?

    if errors.any?
      puts errors.join("\n")
      exit(1)
    end

    puts "OK"
  end
end
