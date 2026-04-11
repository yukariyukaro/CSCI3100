class CreateListings < ActiveRecord::Migration[7.2]
  def change
    create_table :listings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.text :description, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :listings, :status
    add_index :listings, :created_at
  end
end
