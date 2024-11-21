class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable

  has_many :records, dependent: :destroy
  has_one_attached :avatar

  def full_name
    "#{self.first_name} #{self.last_name}"
  end
end
