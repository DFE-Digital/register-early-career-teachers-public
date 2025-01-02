FactoryBot.define do
  factory(:event) do
    sequence(:heading) { |n| "Event #{n}" }
    sequence(:happened_at) { 5.minutes.ago }

    sequence(:author_email) { |n| "user#{n}@something.org" }
    sequence(:author_name) { |n| "User #{n}" }
    author_type { :appropriate_body_user }

    trait(:dfe_staff_user) do
      association :user
      author_type { :dfe_staff_user }
    end

    trait(:school_user) do
      author_type { :school_user }
    end
  end
end
