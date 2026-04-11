class CreateEscrows < ActiveRecord::Migration[7.2]
  def change
    create_table :escrows do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.string :stripe_payment_intent_id

      t.timestamps
    end

    add_index :escrows, :status
    add_index :escrows, :stripe_payment_intent_id
    add_index :escrows, %i[listing_id buyer_id], unique: true
  end
end
