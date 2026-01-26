FactoryBot.define do
  factory(:teacher_lead_provider_metadata, class: "Metadata::TeacherLeadProvider") do
    association :teacher
    association :lead_provider

    transient do
      ect_teacher_type { false }
      mentor_teacher_type { false }
      with_eoi_only { false }
    end

    after(:create) do |metadata, evaluator|
      teacher = metadata.teacher
      lead_provider = metadata.lead_provider

      contract_period = FactoryBot.create(:contract_period, :current)
      active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)

      if evaluator.with_eoi_only
        school = FactoryBot.create(:school)
        school_partnership = nil
        expression_of_interest = active_lead_provider
      else
        lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
        school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
        school = school_partnership.school
        expression_of_interest = nil
      end

      [
        (:ect if evaluator.ect_teacher_type),
        (:mentor if evaluator.mentor_teacher_type),
      ].compact.each do |teacher_type|
        at_school_period = FactoryBot.create(
          :"#{teacher_type}_at_school_period",
          :ongoing,
          school:,
          teacher:
        )

        training_period = FactoryBot.create(
          :training_period,
          :"for_#{teacher_type}",
          started_on: at_school_period.started_on,
          finished_on: at_school_period.finished_on,
          "#{teacher_type}_at_school_period": at_school_period,
          school_partnership:,
          expression_of_interest:
        )

        metadata.public_send("latest_#{teacher_type}_training_period=", training_period)
        metadata.public_send("latest_#{teacher_type}_contract_period=", contract_period)
      end
    end

    trait :with_latest_ect_training_period do
      ect_teacher_type { true }
    end

    trait :with_latest_mentor_training_period do
      mentor_teacher_type { true }
    end

    trait :with_eoi_only do
      with_eoi_only { true }
    end
  end
end
