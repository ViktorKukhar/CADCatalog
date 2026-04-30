class UserReview < ApplicationRecord
  belongs_to :record
  belongs_to :user

  VALID_RATINGS = (1..5).freeze

  scope :for_record, ->(record_id) { where(record_id: record_id) }
  scope :by_rating, -> { order(rating: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :high_rated, ->(threshold = 4) { where('rating >= ?', threshold) }

  validates :rating, presence: true, inclusion: { in: VALID_RATINGS, message: 'must be between 1 and 5' }
  validates :comment, length: { maximum: 1000 }, allow_nil: true
  validates :user_id, uniqueness: { scope: :record_id, message: 'has already reviewed this record' }
  validate :reviewer_cannot_review_own_record

  before_validation :sanitize_input_data

  def self.average_rating_for(record_id)
    where(record_id: record_id).average(:rating)&.round(2)
  end

  private

  def sanitize_input_data
    self.rating = DataSanitizer.sanitize_numeric(rating.to_s)&.to_i if rating.present?
    self.comment = DataSanitizer.sanitize_html(comment) if comment.present?
  end

  def reviewer_cannot_review_own_record
    return unless record && user
    errors.add(:user, 'cannot review their own record') if record.user_id == user_id
  end
end
