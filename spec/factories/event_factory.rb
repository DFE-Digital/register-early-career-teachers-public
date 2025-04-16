FactoryBot.define do
  factory(:event) do
    sequence(:heading) { |n| "Event #{n}" }
    sequence(:happened_at) { 5.minutes.ago }

    sequence(:author_email) { |n| "user#{n}@something.org" }
    sequence(:author_name) { |n| "User #{n}" }
    author_type { :appropriate_body_user }
    event_type { Event::EVENT_TYPES.sample }

    trait(:dfe_staff_user) do
      association :user
      author_type { :dfe_staff_user }
    end

    trait(:school_user) do
      author_type { :school_user }
    end

    trait(:with_body) do
      body { Faker::Lorem.paragraph }
    end

    trait(:with_modifications) do
      modifications { ["Something has changed"] }
    end
  end
end
