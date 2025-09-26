FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    sequence(:name) { |n| "John Doe #{n}" }

    admin

    trait(:admin) { role { 'admin' } }
    trait(:super_admin) { role { 'super_admin' } }
    trait(:finance) { role { 'finance' } }
  end
end
