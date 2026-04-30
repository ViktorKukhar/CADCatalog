class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable

  has_many :records, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :user_reviews, dependent: :destroy
  has_many :record_versions, dependent: :destroy
  has_one_attached :avatar

  # Data sanitization callbacks - ensures all user input is safe from XSS and injection attacks
  before_validation :sanitize_input_data

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  private

  # Sanitizes user profile information to prevent XSS attacks
  # Email is already handled by Devise, but names and other fields are sanitized here
  def sanitize_input_data
    # Sanitize first and last names to prevent XSS
    self.first_name = DataSanitizer.sanitize_text(first_name) if first_name.present?
    self.last_name = DataSanitizer.sanitize_text(last_name) if last_name.present?
  end
end
