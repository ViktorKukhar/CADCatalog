# CadCatalog custom exception hierarchy.
#
# Design rules:
#   • All exceptions inherit from CadCatalogError so callers can rescue the
#     entire domain with a single clause when needed.
#   • Sub-hierarchies group errors by domain; callers can rescue narrowly
#     (DuplicateVersionError) or broadly (VersioningError, CadCatalogError).
#   • Exceptions that carry domain context expose it via named attr_readers
#     so rescue blocks can inspect the value without parsing the message string.

# ── Base ─────────────────────────────────────────────────────────────────────

class CadCatalogError < StandardError; end

# ── Access & authorization ────────────────────────────────────────────────────

class AccessError < CadCatalogError; end

# Raised when a user is not authenticated at all.
class UnauthorizedError < AccessError
  def initialize(msg = 'Authentication is required to access this resource')
    super
  end
end

# Raised when an authenticated user attempts an action they are not permitted.
class AccessDeniedError < AccessError
  attr_reader :resource_type

  def initialize(resource_type = nil)
    @resource_type = resource_type
    msg = resource_type ? "Access denied to #{resource_type}" : 'Access denied'
    super(msg)
  end
end

# ── Data integrity ────────────────────────────────────────────────────────────

class DataIntegrityError < CadCatalogError; end

# Raised when a SHA-256 checksum does not match the stored value.
class ChecksumMismatchError < DataIntegrityError
  def initialize(msg = 'Data checksum mismatch — content may have been modified outside the application')
    super
  end
end

# Raised when an HMAC signature fails verification.
class TamperedDataError < DataIntegrityError
  def initialize(msg = 'Signature verification failed — data integrity cannot be confirmed')
    super
  end
end

# ── Versioning ────────────────────────────────────────────────────────────────

class VersioningError < CadCatalogError; end

# Raised when the supplied version number string does not match the expected
# semantic versioning format (v<major>.<minor>.<patch>).
class InvalidVersionFormatError < VersioningError
  attr_reader :input

  def initialize(input)
    @input = input
    super("'#{input}' is not a valid version number — expected format: v<major>.<minor>.<patch>")
  end
end

# Raised when a version with the same number already exists for the record.
class DuplicateVersionError < VersioningError
  attr_reader :version_number

  def initialize(version_number)
    @version_number = version_number
    super("Version '#{version_number}' already exists for this record")
  end
end

# Raised when a requested version cannot be found.
class VersionNotFoundError < VersioningError
  attr_reader :version_number

  def initialize(version_number = nil)
    @version_number = version_number
    msg = version_number ? "Version '#{version_number}' was not found" : 'Version not found'
    super(msg)
  end
end

# ── Sanitization ──────────────────────────────────────────────────────────────

# Raised by bang sanitization methods when input cannot be made safe.
class SanitizationError < CadCatalogError
  attr_reader :field, :input

  def initialize(field, input)
    @field = field
    @input = input
    super("'#{field}' contains content that cannot be sanitized")
  end
end

# ── Structural / hierarchy ────────────────────────────────────────────────────

# Raised when an operation would create a circular parent-child chain
# (e.g. assigning a Category as its own ancestor).
class CircularAncestryError < CadCatalogError
  def initialize(msg = 'This relationship would create a circular ancestry chain')
    super
  end
end
