class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.references :product,  null: false, foreign_key: true
      t.references :buyer,    null: false, foreign_key: { to_table: :users }
      t.references :seller,   null: false, foreign_key: { to_table: :users }
      t.integer    :status,   null: false, default: 0
      t.datetime   :completed_at

      t.timestamps
    end

    add_index :transactions, %i[buyer_id  created_at]
    add_index :transactions, %i[seller_id created_at]
  end
end
