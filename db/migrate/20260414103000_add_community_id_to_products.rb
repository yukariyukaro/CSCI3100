class AddCommunityIdToProducts < ActiveRecord::Migration[7.2]
  def up
    add_reference :products, :community, foreign_key: true, index: true, null: true unless column_exists?(:products, :community_id)

    execute <<~SQL.squish
      UPDATE products
      SET community_id = users.community_id
      FROM users
      WHERE products.seller_id = users.id
        AND products.community_id IS NULL
    SQL

    default_id = select_value("SELECT id FROM communities ORDER BY id ASC LIMIT 1")
    execute("UPDATE products SET community_id = #{default_id} WHERE community_id IS NULL") if default_id

    change_column_null :products, :community_id, false
  end

  def down
    remove_reference :products, :community if column_exists?(:products, :community_id)
  end
end

