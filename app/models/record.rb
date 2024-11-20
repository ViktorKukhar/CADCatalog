class Record < ApplicationRecord
  belongs_to :user

  has_and_belongs_to_many :tags
  has_many_attached :files
  has_many_attached :images

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 150 }

  def tag_list=(tags_string)
    tag_names = tags_string.split(",").collect { |s| s.strip.downcase }.uniq
    new_or_found_tags = tag_names.collect { |name| Tag.find_or_create_by(name: name) }
    self.tags = new_or_found_tags
  end

  def tag_list
    self.tags.map(&:name).join(", ")
  end

  # private

  # def correct_file_type
  #   if file.attached? && !file.content_type.in?(%w(application/acad application/x-acad application/autocad_dwg image/vnd.dwg application/dwg application/x-dwg))
  #     errors.add(:file, 'must be a DWG file')
  #   end
  # end

end
