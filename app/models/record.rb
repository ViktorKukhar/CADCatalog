class Record < ApplicationRecord
  belongs_to :user

  has_and_belongs_to_many :tags

  validates :title, presence: true, length: { maximum: 15 }
  validates :description, presence: true, length: { maximum: 50 }
end
