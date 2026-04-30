class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.string  :entity_type, null: false
      t.bigint  :entity_id,   null: false
      t.references :user, null: true, foreign_key: true
      t.string  :action,      null: false
      t.string  :field_name
      t.jsonb   :metadata,    default: {}, null: false
      t.string  :ip_address
      t.timestamps
    end

    add_index :audit_logs, [:entity_type, :entity_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
    add_check_constraint :audit_logs, "action IN ('create','update','destroy','read')",
                         name: 'audit_logs_action_values'
  end
end
