FactoryBot.define do
  factory :software do
    name { Faker::App.unique.name }
  end
end
