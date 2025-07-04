FactoryBot.define do
  factory :migration_user, class: "Migration::User" do
    full_name { Faker::FunnyName.two_word_name }
    email { Faker::Internet.unique.email(name: full_name) }
  end
end
