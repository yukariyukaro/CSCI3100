class AddAuthFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :password_digest, :string
    add_index :users, :email, unique: true
  end
end
