class Collection < ApplicationRecord
  include Auditable

  # Description may contain proprietary project context — encrypted at rest.
  encrypts :description

  belongs_to :user
  has_and_belongs_to_many :records

  scope :public_collections, -> { where(public: true) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_creation_date, -> { order(created_at: :desc) }
  scope :with_records, -> { joins(:records).distinct }
  scope :visible_to, ->(user) { user ? where(public: true).or(where(user_id: user.id)) : where(public: true) }

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_nil: true
  validates :name, uniqueness: { scope: :user_id, message: 'already exists in your collections' }

  before_validation :sanitize_input_data

  def record_count
    records.count
  end

  def accessible_by?(current_user)
    public? || user_id == current_user&.id
  end

  private

  def sanitize_input_data
    self.name = DataSanitizer.sanitize_text(name) if name.present?
    self.description = DataSanitizer.sanitize_html(description) if description.present?
  end
end
