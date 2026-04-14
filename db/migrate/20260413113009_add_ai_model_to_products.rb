class AddAiModelToProducts < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:products, :ai_model)

    add_column :products, :ai_model, :string
  end
end
