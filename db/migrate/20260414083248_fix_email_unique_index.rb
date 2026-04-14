class FixEmailUniqueIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, "LOWER(email)", unique: true
  end
end