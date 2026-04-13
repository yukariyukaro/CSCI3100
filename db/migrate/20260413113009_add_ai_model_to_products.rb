class AddAiModelToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :ai_model, :string
  end
end
