class AddCommunityIdToUsers < ActiveRecord::Migration[7.2]
  class Community < ActiveRecord::Base
    self.table_name = "communities"
  end

  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_reference :users, :community, foreign_key: false, index: true, null: true unless column_exists?(:users, :community_id)

    default = Community.find_by(slug: "cuhk") || Community.create!(name: "CUHK Main Campus", abbreviation: "CUHK", slug: "cuhk")
    User.where(community_id: nil).update_all(community_id: default.id)

    change_column_null :users, :community_id, false
    add_foreign_key :users, :communities unless foreign_key_exists?(:users, :communities)
  end

  def down
    remove_foreign_key :users, :communities if foreign_key_exists?(:users, :communities)
    remove_reference :users, :community if column_exists?(:users, :community_id)
  end
end

