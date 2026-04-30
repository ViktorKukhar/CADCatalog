module Auditable
  extend ActiveSupport::Concern

  included do
    after_save    :log_audit_save_event
    after_destroy :log_audit_destroy_event
  end

  private

  def log_audit_save_event
    action = previous_changes.key?('id') ? 'create' : 'update'
    changed_fields = previous_changes.keys - %w[updated_at created_at]
    encrypted_fields = DataProtection.encrypted_attributes_for(self.class).map(&:to_s)
    sensitive_changed = changed_fields & encrypted_fields

    AuditLog.record_event(
      entity:     self,
      user:       Current.user,
      action:     action,
      metadata:   {
        changed_fields:          changed_fields,
        sensitive_fields_changed: sensitive_changed
      }
    )
  end

  def log_audit_destroy_event
    AuditLog.record_event(
      entity:   self,
      user:     Current.user,
      action:   'destroy',
      metadata: { destroyed_at: Time.current.iso8601 }
    )
  end
end
