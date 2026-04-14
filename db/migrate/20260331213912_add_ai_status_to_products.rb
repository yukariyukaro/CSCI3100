class AddAiStatusToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :ai_summary_status, :string, default: 'pending'
    add_column :products, :ai_summary_requested_at, :datetime
  end
end
