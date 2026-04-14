class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # Compound index for filtering active products in a specific community
    add_index :products, [:community_id, :sale_status, :created_at], name: 'index_products_on_community_status_created'
    
    # Compound index for listing seller's products
    add_index :products, [:seller_id, :created_at] unless index_exists?(:products, [:seller_id, :created_at])
  end
end
