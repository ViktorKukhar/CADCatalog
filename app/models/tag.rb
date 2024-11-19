class Tag < ApplicationRecord
  has_and_belongs_to_many :records

  validates :name, presence: true, uniqueness: true, length: { in: 2..10 }
end
