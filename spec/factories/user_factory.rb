FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    sequence(:name) { |n| "John Doe #{n}" }

    admin

    initialize_with do
      User.find_or_initialize_by(email:)
    end

    trait :admin do
      role { "admin" }
      sequence(:email) { |n| "admin.user#{n}@education.gov.uk" }
    end
    trait :user_manager do
      role { "user_manager" }
      sequence(:email) { |n| "user.manager#{n}@education.gov.uk" }
    end

    trait :finance do
      role { "finance" }
      sequence(:email) { |n| "finance.user#{n}@education.gov.uk" }
    end
  end
end
