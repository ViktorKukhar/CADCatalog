class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  ACTIONS = %w[create update destroy read].freeze

  scope :for_entity, ->(type, id) { where(entity_type: type, entity_id: id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :for_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }
  scope :sensitive_changes, -> { where("metadata->>'sensitive_fields_changed' != '[]'") }

  validates :entity_type, presence: true
  validates :entity_id,   presence: true
  validates :action,      presence: true, inclusion: { in: ACTIONS }

  # Creates an audit entry without raising — failures are logged and swallowed
  # so that a broken audit trail never rolls back the primary operation.
  def self.record_event(entity:, user:, action:, field_name: nil, metadata: {}, ip_address: nil)
    create!(
      entity_type: entity.class.name,
      entity_id:   entity.id,
      user_id:     user&.id,
      action:      action,
      field_name:  field_name,
      metadata:    metadata,
      ip_address:  ip_address || Current.ip_address
    )
  rescue StandardError => e
    Rails.logger.error("[AuditLog] Failed to record #{action} on #{entity.class.name}##{entity.id}: #{e.message}")
    nil
  end
end
