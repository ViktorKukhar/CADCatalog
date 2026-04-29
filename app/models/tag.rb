class Tag < ApplicationRecord
  has_and_belongs_to_many :records

  validates :name, presence: true, uniqueness: true, length: { in: 2..10 }

  # Sanitize tag input to prevent injection and XSS attacks
  # Tags are user-provided and require careful sanitization
  before_validation :sanitize_tag_name

  private

  # Sanitizes tag names using framework sanitization
  # Prevents SQL injection and XSS through tag manipulation
  def sanitize_tag_name
    # Use DataSanitizer to clean tag input
    # Only allows safe alphanumeric characters, hyphens, underscores
    self.name = DataSanitizer.sanitize_tag(name) if name.present?
  end
end
