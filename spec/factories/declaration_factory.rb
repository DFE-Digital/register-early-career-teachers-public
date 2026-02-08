FactoryBot.define do
  factory(:declaration) do
    training_period { FactoryBot.create(:training_period) }
    payment_status { :no_payment }
    clawback_status { :no_clawback }
    api_id { SecureRandom.uuid }
    declaration_date { Faker::Date.between(from: Time.zone.now, to: 1.year.from_now) }
    evidence_type do
      detailed_evidence_types_enabled = training_period&.contract_period&.detailed_evidence_types_enabled
      if declaration_type != "started" || detailed_evidence_types_enabled
        if detailed_evidence_types_enabled
          case declaration_type
          when "completed", "retained-2"
            "75-percent-engagement-met"
          else
            %w[
              training-event-attended
              self-study-material-completed
              materials-engaged-with-offline
              other
            ].sample
          end
        else
          %w[
            training-event-attended
            self-study-material-completed
            other
          ].sample
        end
      end
    end
    declaration_type { Declaration.declaration_types.keys.first }
    delivery_partner_when_created do
      if training_period.present?
        training_period.delivery_partner
      else
        association :delivery_partner
      end
    end

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
      payment_statement { FactoryBot.create(:statement, :open, active_lead_provider: training_period.active_lead_provider) }
    end

    trait :payable do
      payment_status { :payable }
      payment_statement { FactoryBot.create(:statement, :payable, active_lead_provider: training_period.active_lead_provider) }
    end

    trait :paid do
      payment_status { :paid }
      payment_statement { FactoryBot.create(:statement, :paid, active_lead_provider: training_period.active_lead_provider) }
    end

    trait :voided do
      payment_status { :voided }
      payment_statement { FactoryBot.create(:statement, :paid, active_lead_provider: training_period.active_lead_provider) }
    end

    trait :awaiting_clawback do
      paid
      clawback_status { :awaiting_clawback }
      clawback_statement { FactoryBot.create(:statement, :payable, active_lead_provider: training_period.active_lead_provider) }
    end

    trait :clawed_back do
      paid
      clawback_status { :clawed_back }
      clawback_statement { FactoryBot.create(:statement, :paid, active_lead_provider: training_period.active_lead_provider) }
    end
  end
end
