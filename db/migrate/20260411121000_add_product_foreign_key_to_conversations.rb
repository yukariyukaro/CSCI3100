class AddProductForeignKeyToConversations < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :conversations, :products
  end
end
