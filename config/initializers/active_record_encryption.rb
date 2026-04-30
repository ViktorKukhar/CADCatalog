# Rails 7.1 ActiveRecord::Encryption provides transparent field-level encryption.
# Sensitive attributes (PII, private comments, change logs) are encrypted before
# being written to the database and decrypted transparently on read.
#
# Setup instructions:
#   1. Generate keys:  bin/rails db:encryption:init
#   2. Store output:   bin/rails credentials:edit
#      Under the key:
#        active_record_encryption:
#          primary_key: <generated>
#          deterministic_key: <generated>
#          key_derivation_salt: <generated>
#
# Alternatively, export as environment variables:
#   ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
#   ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
#   ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT

credentials = Rails.application.credentials.dig(:active_record_encryption)

if credentials.blank? && ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'].present?
  ActiveRecord::Encryption.configure do |config|
    config.primary_key         = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
    config.deterministic_key   = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
    config.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']
  end
end

ActiveRecord::Encryption.configure do |config|
  # Allow reading plaintext values written before encryption was enabled.
  # Disable in production once all existing rows have been encrypted.
  config.support_unencrypted_data = !Rails.env.production?

  # Enables encrypted equality queries (e.g. User.find_by(username: ...)).
  # Requires deterministic encryption for the queried attribute.
  config.extend_queries = true
end
