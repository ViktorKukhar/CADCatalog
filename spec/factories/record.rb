FactoryBot.define do
  factory :record do
    title { "#{Faker::Construction.material} Design File" }
    description { Faker::Lorem.paragraph }
    association :user
    created_at { Faker::Time.between(from: 1.years.ago, to: Time.now) }
  end
end