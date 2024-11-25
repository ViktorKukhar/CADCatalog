FactoryBot.define do
  factory :tag do
    name { Faker::Construction.unique.material }
  end
end