class AddAiSummaryToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :ai_summary, :text
  end
end
