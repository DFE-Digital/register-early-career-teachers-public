FactoryBot.define do
  factory(:appropriate_body) do
    sequence(:name) { |n| "Appropriate Body #{n}" }
    sequence(:local_authority_code, 55) { |n| 55 + (n % 945) }
    sequence(:establishment_number) { |n| 1000 + (n / 945) }
    dfe_sign_in_organisation_id { SecureRandom.uuid }
    teaching_school_hub

    trait :istip do
      body_type { 'national' }
      name { AppropriateBody::ISTIP }
      local_authority_code { 50 }
      dfe_sign_in_organisation_id { "203606a4-4199-46a9-84e4-56fbc5da2a36" }
    end

    trait :local_authority do
      body_type { 'local_authority' }
    end

    trait :national do
      body_type { 'national' }
    end

    trait :teaching_school_hub do
      body_type { 'teaching_school_hub' }
    end
  end
end
