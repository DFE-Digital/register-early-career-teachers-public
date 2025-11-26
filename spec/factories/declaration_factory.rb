FactoryBot.define do
  factory(:declaration) do
    training_period
    status { :submitted }
    api_id { SecureRandom.uuid }
    date { Faker::Date.between(from: Time.zone.now, to: 1.year.from_now) }
    evidence_type { Declaration.evidence_types.keys.sample }
    declaration_type { Declaration.declaration_types.keys.first }
    billable_statement { nil }
    refundable_statement { nil }

    trait :voided_by_user do
      status { :voided }
      voided_by_user { FactoryBot.create(:user) }
      voided_at { Time.zone.now }
    end

    trait :eligible do
      status { :eligible }
      association :billable_statement, factory: %i[statement open]
    end

    trait :payable do
      status { :payable }
      association :billable_statement, factory: %i[statement payable]
    end

    trait :paid do
      status { :paid }
      association :billable_statement, factory: %i[statement paid]
    end

    trait :voided do
      status { :voided }
    end

    trait :ineligible do
      status { :ineligible }
      ineligibility_reason { Declaration.ineligibility_reasons.keys.sample }
    end

    trait :awaiting_clawback do
      status { :awaiting_clawback }
      association :refundable_statement, factory: %i[statement payable]
    end

    trait :clawed_back do
      status { :clawed_back }
      association :refundable_statement, factory: %i[statement paid]
    end
  end
end
