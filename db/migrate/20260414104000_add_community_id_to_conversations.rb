class AddCommunityIdToConversations < ActiveRecord::Migration[7.2]
  def up
    add_reference :conversations, :community, foreign_key: true, index: true, null: true unless column_exists?(:conversations, :community_id)

    execute <<~SQL.squish
      UPDATE conversations
      SET community_id = products.community_id
      FROM products
      WHERE conversations.product_id = products.id
        AND conversations.community_id IS NULL
    SQL

    default_id = select_value("SELECT id FROM communities ORDER BY id ASC LIMIT 1")
    execute("UPDATE conversations SET community_id = #{default_id} WHERE community_id IS NULL") if default_id

    change_column_null :conversations, :community_id, false
  end

  def down
    remove_reference :conversations, :community if column_exists?(:conversations, :community_id)
  end
end

