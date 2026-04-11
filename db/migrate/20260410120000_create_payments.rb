class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :transaction, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.string :provider, null: false
      t.string :provider_reference
      t.string :callback_token
      t.text :error_details
      t.datetime :resolved_at
      t.bigint :resolved_by_id
      t.timestamps
    end

    add_index :payments, %i[provider provider_reference],
              unique: true,
              where: "provider_reference IS NOT NULL"

    add_index :payments, :status
    add_index :payments, :resolved_by_id
    add_foreign_key :payments, :users, column: :resolved_by_id
  end
end

