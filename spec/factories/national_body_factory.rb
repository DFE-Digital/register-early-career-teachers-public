FactoryBot.define do
  factory(:national_body) do
    initialize_with do
      NationalBody.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "National Body #{n}" }

    trait :istip do
      name { AppropriateBody::ISTIP }
    end

    trait :esp do
      name { AppropriateBody::ESP }
    end
  end
end
