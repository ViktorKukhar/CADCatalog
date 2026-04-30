class RecordVersion < ApplicationRecord
  belongs_to :record
  belongs_to :user

  scope :for_record, ->(record_id) { where(record_id: record_id).order(created_at: :desc) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :with_dimensions, -> { where.not(width: nil, height: nil, depth: nil) }

  SEMVER_FORMAT = /\Av?\d+(\.\d+){0,2}\z/

  validates :version_number, presence: true,
                             format: { with: SEMVER_FORMAT, message: 'must follow versioning format (e.g. v1.0.0)' }
  validates :version_number, uniqueness: { scope: :record_id, message: 'already exists for this record' }
  validates :change_log, length: { maximum: 2000 }, allow_nil: true
  validates :width, :height, :depth, numericality: { greater_than: 0 }, allow_nil: true
  validates :rotation_angle, numericality: { greater_than_or_equal_to: 0, less_than: 360 }, allow_nil: true
  validates :complexity_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :sanitize_input_data

  def snapshot_dimensions
    { width: width, height: height, depth: depth, rotation_angle: rotation_angle }
  end

  def has_geometry?
    width.present? && height.present? && depth.present?
  end

  private

  def sanitize_input_data
    self.version_number = DataSanitizer.sanitize_version_number(version_number) if version_number.present?
    self.change_log = DataSanitizer.sanitize_html(change_log) if change_log.present?
  end
end
