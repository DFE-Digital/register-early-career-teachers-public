FactoryBot.define do
  factory(:teacher_lead_provider_metadata, class: "Metadata::TeacherLeadProvider") do
    association :teacher
    association :lead_provider

    trait :with_latest_ect_training_period do
      latest_ect_training_period do
        contract_period = FactoryBot.create(:contract_period, :current)
        active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
        lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
        school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
        school = school_partnership.school
        ect_at_school_period = FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          school:,
          teacher:
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.finished_on,
          ect_at_school_period:,
          school_partnership:
        )
      end
    end

    trait :with_latest_mentor_training_period do
      latest_mentor_training_period do
        contract_period = FactoryBot.create(:contract_period, :current)
        active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
        lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
        school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
        school = school_partnership.school
        mentor_at_school_period = FactoryBot.create(
          :mentor_at_school_period,
          :ongoing,
          school:,
          teacher:
        )

        FactoryBot.create(
          :training_period,
          :for_mentor,
          started_on: mentor_at_school_period.started_on,
          finished_on: mentor_at_school_period.finished_on,
          mentor_at_school_period:,
          school_partnership:
        )
      end
    end
  end
end
