class CreatePaymentWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_webhook_events do |t|
      t.string :provider, null: false
      t.string :event_id, null: false
      t.references :payment, null: true, foreign_key: true
      t.datetime :processed_at

      t.timestamps
    end

    add_index :payment_webhook_events, %i[provider event_id], unique: true
  end
end
