class CreateAuditEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_events do |t|
      t.references :community, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.json :metadata, null: false, default: {}
      t.string :request_id
      t.string :ip
      t.string :user_agent

      t.timestamps
    end

    add_index :audit_events, %i[auditable_type auditable_id]
    add_index :audit_events, :action
    add_index :audit_events, :created_at
  end
end
