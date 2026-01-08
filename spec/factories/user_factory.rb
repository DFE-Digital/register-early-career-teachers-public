FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    sequence(:name) { |n| "John Doe #{n}" }

    admin

    initialize_with do
      User.find_or_initialize_by(email:)
    end

    trait(:admin) { role { "admin" } }
    trait(:user_manager) { role { "user_manager" } }
    trait(:super_admin) { role { "user_manager" } }
    trait(:finance) { role { "finance" } }
  end
end
