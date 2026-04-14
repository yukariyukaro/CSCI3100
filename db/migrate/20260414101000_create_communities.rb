class CreateCommunities < ActiveRecord::Migration[7.2]
  def change
    create_table :communities do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.string :slug, null: false
      t.text :description

      t.integer :max_active_products_per_user, null: false, default: 50

      t.timestamps
    end

    add_index :communities, :slug, unique: true
    add_index :communities, :abbreviation, unique: true
    add_index :communities, :name, unique: true
  end
end

