FactoryBot.define do
  factory(:declaration) do
    training_period
    payment_status { :no_payment }
    clawback_status { :no_clawback }
    api_id { SecureRandom.uuid }
    declaration_date { Faker::Date.between(from: Time.zone.now, to: 1.year.from_now) }
    evidence_type { Declaration.evidence_types.keys.sample }
    declaration_type { Declaration.declaration_types.keys.first }

    trait :voided_by_user do
      payment_status { :voided }
      voided_by_user { FactoryBot.create(:user) }
      voided_at { Time.zone.now }
    end

    trait :eligible do
      payment_status { :eligible }
      association :payment_statement, factory: %i[statement open]
    end

    trait :payable do
      payment_status { :payable }
      association :payment_statement, factory: %i[statement payable]
    end

    trait :paid do
      payment_status { :paid }
      association :payment_statement, factory: %i[statement paid]
    end

    trait :voided do
      payment_status { :voided }
      association :payment_statement, factory: %i[statement paid]
    end

    trait :ineligible do
      payment_status { :ineligible }
      association :payment_statement, factory: %i[statement paid]
      ineligibility_reason { Declaration.ineligibility_reasons.keys.sample }
    end

    trait :awaiting_clawback do
      paid
      clawback_status { :awaiting_clawback }
      association :clawback_statement, factory: %i[statement payable]
    end

    trait :clawed_back do
      paid
      clawback_status { :clawed_back }
      association :clawback_statement, factory: %i[statement paid]
    end
  end
end
