FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.password(min_length: 8) }
    encrypted_password { Faker::Internet.password(min_length: 8) }
    username { Faker::Internet.unique.username }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    position { Faker::Job.title }
  end
end
