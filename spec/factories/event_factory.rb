FactoryBot.define do
  factory(:event) do
    sequence(:heading) { |n| "Event #{n}" }
    sequence(:happened_at) { 5.minutes.ago }

    sequence(:author_email) { |n| "user#{n}@something.org" }
    sequence(:author_name) { |n| "User #{n}" }

    trait(:dfe_staff_user) do
      author_name nil
      author_emali nil
      association :user
    end
  end
end
