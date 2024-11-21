class Record < ApplicationRecord
  searchkick

  belongs_to :user

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :softwares
  has_many_attached :files
  has_many_attached :images

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 150 }

  def search_data
    {
      name: title,
      tags: tags.map(&:name),
      softwares: softwares.map(&:name),
      user_name: user.full_name,
      user_username: user.username
    }
  end

  def tag_list=(tags_string)
    tag_names = tags_string.split(",").collect { |s| s.strip.downcase }.uniq
    new_or_found_tags = tag_names.collect { |name| Tag.find_or_create_by(name: name) }
    self.tags = new_or_found_tags
  end

  def tag_list
    self.tags.map(&:name).join(", ")
  end

  def software_list=(softwares_string)
    software_names = softwares_string.split(",").collect { |s| s.strip.downcase }.uniq
    new_or_found_softwares = software_names.collect { |name| Software.find_or_create_by(name: name) }
    self.softwares = new_or_found_softwares
  end

  def software_list
    self.softwares.map(&:name).join(", ")
  end
end
