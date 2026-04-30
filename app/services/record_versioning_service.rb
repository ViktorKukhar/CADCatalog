# RecordVersioningService - Atomic version management for CAD records.
#
# Every public method wraps all DB writes in a single transaction so that a
# version snapshot and the corresponding record update always succeed or fail
# together. Domain-specific preconditions are validated before entering the
# transaction so callers receive descriptive custom exceptions (not raw
# ActiveRecord errors) for known failure modes.
#
# Custom exceptions raised:
#   InvalidVersionFormatError — version_number does not match v<major>.<minor>.<patch>
#   DuplicateVersionError     — that version number already exists on the record
#   VersionNotFoundError      — target_version argument is nil or missing
#   VersioningError           — unexpected DB failure during commit or rollback

class RecordVersioningService
  # Snapshots the record's current geometry into a new RecordVersion and,
  # optionally, updates the record with new attribute values — all in one
  # transaction. Validates format and uniqueness before touching the database.
  def self.commit_version(record:, user:, version_number:, change_log: nil, new_attributes: {})
    validate_version_format!(version_number)
    validate_version_unique!(record, version_number)

    ActiveRecord::Base.transaction do
      version = RecordVersion.create!(
        record:           record,
        user:             user,
        version_number:   version_number,
        change_log:       change_log,
        width:            record.width,
        height:           record.height,
        depth:            record.depth,
        rotation_angle:   record.rotation_angle,
        complexity_score: record.complexity_score
      )

      record.update!(new_attributes) if new_attributes.present?

      version
    end
  rescue InvalidVersionFormatError, DuplicateVersionError
    raise
  rescue ActiveRecord::RecordInvalid => e
    raise VersioningError, "commit_version failed for Record##{record.id}: #{e.message}"
  end

  # Restores a record's geometry from a previous snapshot. A new RecordVersion
  # is created to mark the rollback point, and the record's dimension columns
  # are updated — both writes inside one transaction.
  def self.rollback_to_version(record:, target_version:, user:, change_log: nil)
    raise VersionNotFoundError if target_version.nil?

    rollback_number = next_patch_version(record)
    validate_version_format!(rollback_number)

    ActiveRecord::Base.transaction do
      rollback_version = RecordVersion.create!(
        record:           record,
        user:             user,
        version_number:   rollback_number,
        change_log:       change_log || "Rolled back to #{target_version.version_number}",
        width:            target_version.width,
        height:           target_version.height,
        depth:            target_version.depth,
        rotation_angle:   target_version.rotation_angle,
        complexity_score: target_version.complexity_score
      )

      record.update!(
        width:          target_version.width,
        height:         target_version.height,
        depth:          target_version.depth,
        rotation_angle: target_version.rotation_angle
      )

      rollback_version
    end
  rescue VersionNotFoundError, InvalidVersionFormatError
    raise
  rescue ActiveRecord::RecordInvalid => e
    raise VersioningError, "rollback_to_version failed for Record##{record.id}: #{e.message}"
  end

  # Destroys all version history for a record inside a transaction.
  def self.purge_versions(record:, user:)
    ActiveRecord::Base.transaction do
      count = record.record_versions.count
      record.record_versions.destroy_all
      Rails.logger.info("[RecordVersioningService] Purged #{count} versions for Record##{record.id} by User##{user&.id}")
      count
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    raise VersioningError, "purge_versions failed for Record##{record.id}: #{e.message}"
  end

  private

  def self.validate_version_format!(version_number)
    raise InvalidVersionFormatError.new(version_number) unless version_number.to_s =~ RecordVersion::SEMVER_FORMAT
  end

  def self.validate_version_unique!(record, version_number)
    raise DuplicateVersionError.new(version_number) if record.record_versions.exists?(version_number: version_number)
  end

  # Derives the next semantic patch version from the record's most recent version.
  # Always outputs the full three-part v<major>.<minor>.<patch> format.
  def self.next_patch_version(record)
    latest = record.record_versions.order(created_at: :desc).first
    return 'v1.0.0' unless latest

    clean = latest.version_number.to_s.gsub(/\Av/, '')
    major, minor, patch = (clean.split('.').map(&:to_i) + [0, 0, 0]).first(3)
    "v#{major}.#{minor}.#{patch + 1}"
  end
end
