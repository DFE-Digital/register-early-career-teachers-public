FactoryBot.define do
  factory(:declaration) do
    training_period
    status { :submitted }
    api_id { SecureRandom.uuid }
    date { Faker::Date.between(from: Time.zone.now, to: 1.year.from_now) }
    evidence_type { Declaration.evidence_types.keys.sample }
    declaration_type { Declaration.declaration_types.keys.first }

    trait :voided_by_user do
      status { :voided }
      voided_by_user { FactoryBot.create(:user) }
      voided_at { Time.zone.now }
    end

    trait :ineligible do
      status { :ineligible }
      ineligibility_reason { Declaration.ineligibility_reasons.keys.sample }
    end
  end
end
