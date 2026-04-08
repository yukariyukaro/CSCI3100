class AddSellerIdAndSaleStatusToProducts < ActiveRecord::Migration[7.2]
  def change
    add_reference :products, :seller, null: true, foreign_key: { to_table: :users }
    add_column :products, :sale_status, :integer, default: 0, null: false
  end
end
