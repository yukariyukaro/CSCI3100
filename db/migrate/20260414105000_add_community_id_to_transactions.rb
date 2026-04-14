class AddCommunityIdToTransactions < ActiveRecord::Migration[7.2]
  def up
    add_reference :transactions, :community, foreign_key: true, index: true, null: true unless column_exists?(:transactions, :community_id)

    execute <<~SQL.squish
      UPDATE transactions
      SET community_id = products.community_id
      FROM products
      WHERE transactions.product_id = products.id
        AND transactions.community_id IS NULL
    SQL

    default_id = select_value("SELECT id FROM communities ORDER BY id ASC LIMIT 1")
    execute("UPDATE transactions SET community_id = #{default_id} WHERE community_id IS NULL") if default_id

    change_column_null :transactions, :community_id, false
  end

  def down
    remove_reference :transactions, :community if column_exists?(:transactions, :community_id)
  end
end

