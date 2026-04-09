class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :product, null: false, foreign_key: true
      t.references :buyer,   null: false, foreign_key: { to_table: :users }
      t.references :seller,  null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :conversations, %i[product_id buyer_id], unique: true
  end
end
