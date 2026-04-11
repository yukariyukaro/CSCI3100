class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :escrow, null: true, foreign_key: true
      t.integer :transaction_type, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.string :stripe_payment_intent_id

      t.timestamps
    end

    add_index :payments, :transaction_type
    add_index :payments, :status
    add_index :payments, :stripe_payment_intent_id
  end
end
