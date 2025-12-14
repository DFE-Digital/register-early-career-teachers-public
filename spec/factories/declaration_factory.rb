FactoryBot.define do
  factory(:declaration) do
    training_period { FactoryBot.create(:training_period) }
    payment_status { :no_payment }
    clawback_status { :no_clawback }
    api_id { SecureRandom.uuid }
    declaration_date { Faker::Date.between(from: Time.zone.now, to: 1.year.from_now) }
    evidence_type { Declaration.evidence_types.keys.sample }
    declaration_type { Declaration.declaration_types.keys.first }

    trait :voided_by_user do
      payment_status { :voided }
      voided_by_user { FactoryBot.create(:user) }
      voided_by_user_at { Time.zone.now }
    end

    trait :no_payment do
      payment_status { :no_payment }
    end

    trait :eligible do
      payment_status { :eligible }
      payment_statement { FactoryBot.create(:statement, :open, contract_period: training_period.contract_period) }
    end

    trait :payable do
      payment_status { :payable }
      payment_statement { FactoryBot.create(:statement, :payable, contract_period: training_period.contract_period) }
    end

    trait :paid do
      payment_status { :paid }
      payment_statement { FactoryBot.create(:statement, :paid, contract_period: training_period.contract_period) }
    end

    trait :voided do
      payment_status { :voided }
      payment_statement { FactoryBot.create(:statement, :paid, contract_period: training_period.contract_period) }
    end

    trait :ineligible do
      payment_status { :ineligible }
      payment_statement { FactoryBot.create(:statement, :paid, contract_period: training_period.contract_period) }
      ineligibility_reason { Declaration.ineligibility_reasons.keys.sample }
    end

    trait :awaiting_clawback do
      paid
      clawback_status { :awaiting_clawback }
      clawback_statement { FactoryBot.create(:statement, :payable, contract_period: training_period.contract_period) }
    end

    trait :clawed_back do
      paid
      clawback_status { :clawed_back }
      clawback_statement { FactoryBot.create(:statement, :paid, contract_period: training_period.contract_period) }
    end
  end
end
