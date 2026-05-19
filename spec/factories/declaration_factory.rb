FactoryBot.define do
  factory(:declaration) do
    transient do
      active_lead_provider { FactoryBot.create(:active_lead_provider) }
    end

    training_period { FactoryBot.create(:training_period, :with_active_lead_provider, active_lead_provider:) }

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

    # Use when the declaration should count toward `replacement_schedule?`,
    # which expects a declaration within the mentor's mentorship of the ECT.
    trait :within_mentorship_period do
      declaration_date do
        mp = training_period&.mentor_at_school_period&.mentorship_periods&.order(:started_on)&.first
        raise ArgumentError, "Cannot derive declaration_date: training_period must belong to a mentor with a mentorship_period" unless mp

        mp.started_on + 1.day
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

    trait :billable_or_changeable do
      Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES.sample
    end

    trait :with_ect do
      transient do
        school_partnership { nil }
        training_period { nil }
        active_lead_provider { nil }
        started_on { declaration_date }
        declaration_type { "started" }
        payment_status { "no_payment" }
        payment_statement { nil }
        clawback_status { "no_clawback" }
        clawback_statement { nil }
      end

      after(:build) do |declaration, evaluator|
        school_partnership = evaluator.school_partnership || create(:school_partnership)
        declaration.declaration_type = evaluator.declaration_type
        payment_status = evaluator.payment_status
        clawback_status = evaluator.clawback_status

        teacher = create(:teacher)
        school = school_partnership.school
        active_lead_provider = school_partnership.active_lead_provider

        ect_at_school_period =
          create(
            :ect_at_school_period,
            teacher:,
            school:,
            started_on: evaluator.started_on,
            finished_on: nil
          )

        training_period =
          create(
            :training_period,
            :for_ect,
            :with_schedule_and_milestones,
            :with_school_partnership,
            ect_at_school_period:,
            started_on: evaluator.started_on,
            finished_on: nil,
            school_partnership:,
            training_programme: "provider_led"
          )

        declaration.training_period = training_period
        milestone = training_period.schedule.milestones.find { |m| m.declaration_type == declaration.declaration_type }
        declaration.declaration_date = milestone.start_date + 1.day
        declaration.payment_status = payment_status
        declaration.clawback_status = clawback_status

        if Declaration::BILLABLE_PAYMENT_STATUSES.include?(payment_status) && !evaluator.payment_statement
          statement_trait = payment_status == "eligable" ? :open : payment_status.to_sym
          declaration.payment_statement = FactoryBot.create(:statement, statement_trait, active_lead_provider:)
        else
          declaration.payment_statement = evaluator.payment_statement
        end

        if Declaration::REFUNDABLE_CLAWBACK_STATUSES.include?(clawback_status) && !evaluator.clawback_statement
          statement_trait = clawback_status == "awaiting_clawback" ? :payable : :paid
          declaration.clawback_statement = FactoryBot.create(:statement, statement_trait, active_lead_provider:)
        else
          declaration.clawback_statement = evaluator.clawback_statement
        end
      end
    end

    trait :with_mentor do
      transient do
        school_partnership { nil }
        training_period { nil }
        active_lead_provider { nil }
        started_on { declaration_date }
        declaration_type { "started" }
        payment_status { "no_payment" }
        payment_statement { nil }
        clawback_status { "no_clawback" }
        clawback_statement { nil }
      end

      after(:build) do |declaration, evaluator|
        school_partnership = evaluator.school_partnership
        declaration.declaration_type = evaluator.declaration_type
        evaluator.payment_status
        payment_status = evaluator.payment_status
        clawback_status = evaluator.clawback_status

        teacher = create(:teacher)
        school = school_partnership.school
        active_lead_provider = school_partnership.active_lead_provider

        mentor_at_school_period = create(
          :mentor_at_school_period,
          teacher:,
          school:,
          started_on: evaluator.started_on,
          finished_on: nil
        )

        training_period =
          create(
            :training_period,
            :for_mentor,
            :with_schedule_and_milestones,
            :with_school_partnership,
            mentor_at_school_period:,
            started_on: evaluator.started_on,
            finished_on: nil,
            school_partnership:,
            training_programme: "provider_led"
          )

        declaration.training_period = training_period
        milestone = training_period.schedule.milestones.find { |m| m.declaration_type == declaration.declaration_type }
        declaration.declaration_date = milestone.start_date + 1.day
        declaration.payment_status = payment_status
        declaration.clawback_status = clawback_status

        if Declaration::BILLABLE_PAYMENT_STATUSES.include?(payment_status) && !evaluator.payment_statement
          statement_trait = payment_status == "eligable" ? :open : payment_status.to_sym
          declaration.payment_statement = FactoryBot.create(:statement, statement_trait, active_lead_provider:)
        else
          declaration.payment_statement = evaluator.payment_statement
        end

        if Declaration::REFUNDABLE_CLAWBACK_STATUSES.include?(clawback_status) && !evaluator.clawback_statement
          statement_trait = clawback_status == "awaiting_clawback" ? :payable : :paid
          declaration.clawback_statement = FactoryBot.create(:statement, statement_trait, active_lead_provider:)
        else
          declaration.clawback_statement = evaluator.clawback_statement
        end
      end
    end
  end
end
