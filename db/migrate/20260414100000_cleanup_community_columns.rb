class CleanupCommunityColumns < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :community_id if column_exists?(:users, :community_id)
    remove_column :products, :community_id if column_exists?(:products, :community_id)
    remove_column :conversations, :community_id if column_exists?(:conversations, :community_id)
    remove_column :transactions, :community_id if column_exists?(:transactions, :community_id)

    drop_table :communities, if_exists: true
    drop_table :audit_events, if_exists: true
  end
end

