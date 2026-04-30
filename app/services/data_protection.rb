# DataProtection - Implements the data protection strategy for CADCatalog.
# Complements DataPrivacy (access control) by focusing on cryptographic guarantees:
#   • Encryption registry — canonical source of which fields are encrypted per model
#   • Integrity checking  — SHA-256 checksums to detect tampering
#   • HMAC signing        — tamper-evident signatures for sensitive payloads
#   • Secure tokens       — cryptographically random values for keys, reset links, etc.
#
# The actual at-rest encryption is handled declaratively via ActiveRecord::Encryption
# (the `encrypts` directive in each model). This service provides the surrounding
# utility layer that models and controllers call explicitly.

require 'digest'
require 'openssl'

class DataProtection
  # Registry of model attributes that are encrypted at rest via ActiveRecord::Encryption.
  # Keep this in sync with the `encrypts` declarations in each model.
  ENCRYPTED_ATTRIBUTES = {
    'User'          => %i[first_name last_name position],
    'UserReview'    => %i[comment],
    'Collection'    => %i[description],
    'RecordVersion' => %i[change_log]
  }.freeze

  # Returns the list of encrypted attribute names for a given model class.
  def self.encrypted_attributes_for(model_class)
    ENCRYPTED_ATTRIBUTES[model_class.name] || []
  end

  # Returns true if the model class has any encrypted attributes configured.
  def self.has_encrypted_attributes?(model_class)
    encrypted_attributes_for(model_class).any?
  end

  # Returns a summary of the protection posture for a given model class.
  def self.protection_profile(model_class)
    {
      model:             model_class.name,
      encrypted_fields:  encrypted_attributes_for(model_class),
      encryption_active: has_encrypted_attributes?(model_class),
      audit_active:      model_class.include?(Auditable)
    }
  end

  # --- Integrity ---

  # Generates a SHA-256 hex digest for the given data.
  # Use to detect whether a stored value has been tampered with out-of-band.
  def self.generate_checksum(data)
    return nil if data.nil?
    Digest::SHA256.hexdigest(data.to_s)
  end

  # Returns true if the data matches the previously stored checksum.
  # Uses constant-time comparison to prevent timing attacks.
  def self.verify_checksum(data, expected_checksum)
    return false if data.nil? || expected_checksum.nil?
    ActiveSupport::SecurityUtils.secure_compare(generate_checksum(data), expected_checksum)
  end

  # --- HMAC signing ---

  # Produces an HMAC-SHA256 hex digest binding data to the application secret.
  # Use to sign tokens, export payloads, or any value that leaves the application boundary.
  def self.sign(data, secret: Rails.application.secret_key_base)
    return nil if data.nil?
    OpenSSL::HMAC.hexdigest('SHA256', secret, data.to_s)
  end

  # Returns true if the signature is valid for the given data.
  # Uses constant-time comparison to prevent timing attacks.
  def self.verify_signature(data, signature, secret: Rails.application.secret_key_base)
    return false if data.nil? || signature.nil?
    ActiveSupport::SecurityUtils.secure_compare(sign(data, secret: secret), signature)
  end

  # --- Secure token generation ---

  # Returns a cryptographically random hex string of the given byte length.
  # Suitable for API keys, password reset tokens, and similar one-time secrets.
  def self.generate_secure_token(byte_length = 32)
    SecureRandom.hex(byte_length)
  end
end
