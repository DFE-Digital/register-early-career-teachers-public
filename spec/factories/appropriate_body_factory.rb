FactoryBot.define do
  factory(:appropriate_body) do
    sequence(:name) { |n| "Appropriate Body #{n}" }
    sequence(:local_authority_code, 100)
    sequence(:establishment_number, 1000)
    dfe_sign_in_organisation_id { SecureRandom.uuid }
    teaching_school_hub

    trait :istip do
      type { 'national' }
      name { AppropriateBody::ISTIP }
      local_authority_code { 50 }
      dfe_sign_in_organisation_id { "203606a4-4199-46a9-84e4-56fbc5da2a36" }
    end

    trait :local_authority do
      type { 'local_authority' }
    end

    trait :national do
      type { 'national' }
    end

    trait :teaching_school_hub do
      type { 'teaching_school_hub' }
    end
  end
end
