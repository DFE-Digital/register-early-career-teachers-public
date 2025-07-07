FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    sequence(:name) { |n| "John Doe #{n}" }

    trait :admin do
      after(:create) do |user|
        create(:dfe_role, :admin, user:)
      end
    end

    trait :super_admin do
      after(:create) do |user|
        create(:dfe_role, :super_admin, user:)
      end
    end

    trait :finance do
      after(:create) do |user|
        create(:dfe_role, :finance, user:)
      end
    end
  end
end
