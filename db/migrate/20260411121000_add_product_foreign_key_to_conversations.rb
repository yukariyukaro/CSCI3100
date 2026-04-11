class AddProductForeignKeyToConversations < ActiveRecord::Migration[7.1]
  def up
    return if foreign_key_exists?(:conversations, :products, column: :product_id)

    add_foreign_key :conversations, :products, column: :product_id
  end

  def down
    return unless foreign_key_exists?(:conversations, :products, column: :product_id)

    remove_foreign_key :conversations, column: :product_id
  end
end
