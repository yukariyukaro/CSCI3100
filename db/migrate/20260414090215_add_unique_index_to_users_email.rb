class AddUniqueIndexToUsersEmail < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, name: "index_users_on_LOWER_email" rescue nil

    add_index :users, :email, unique: true
  end
end