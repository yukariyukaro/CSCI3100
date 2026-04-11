class AddEscrowColumnsToPayments < ActiveRecord::Migration[7.2]
  def change
    add_reference :payments, :user, null: true, foreign_key: true
    add_reference :payments, :escrow, null: true, foreign_key: true
    add_column :payments, :transaction_type, :integer, null: true
    add_column :payments, :stripe_payment_intent_id, :string

    add_index :payments, :transaction_type
    add_index :payments, :stripe_payment_intent_id
  end
end
