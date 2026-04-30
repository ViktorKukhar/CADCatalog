class Category < ApplicationRecord
  belongs_to :parent_category, class_name: 'Category', optional: true
  has_many :subcategories, class_name: 'Category', foreign_key: :parent_category_id, dependent: :destroy
  has_and_belongs_to_many :records

  scope :root_categories, -> { where(parent_category_id: nil) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :with_records, -> { joins(:records).distinct }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }, allow_nil: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :no_circular_ancestry

  before_validation :sanitize_input_data

  def root?
    parent_category_id.nil?
  end

  def ancestors
    return [] if root?
    [parent_category] + parent_category.ancestors
  end

  def full_path
    (ancestors.reverse + [self]).map(&:name).join(' > ')
  end

  def depth_level
    ancestors.count
  end

  private

  def sanitize_input_data
    self.name = DataSanitizer.sanitize_text(name) if name.present?
    self.description = DataSanitizer.sanitize_html(description) if description.present?
  end

  def no_circular_ancestry
    return if parent_category_id.nil? || id.nil?
    if parent_category_id == id
      errors.add(:parent_category, 'cannot be itself')
      return
    end
    errors.add(:parent_category, 'creates a circular reference') if ancestors.any? { |a| a.id == id }
  end
end
