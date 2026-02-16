FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.number(digits: 6) }
    independent

    initialize_with do
      School.find_or_initialize_by(urn:)
    end

    after(:build) do |school|
      school.induction_tutor_name ||= "Induction Tutor"
      school.induction_tutor_email ||= "induction.tutor@a-very-nice-school.sch.uk"
      school.induction_tutor_last_nominated_in ||= build(:contract_period, :current)
    end

    trait :independent do
      gias_school { association :gias_school, :independent_school_type, :section_41, urn: }
    end

    trait :state_funded do
      gias_school { association :gias_school, :open, :eligible, :state_school_type, urn: }
    end

    trait :provider_led_last_chosen do
      last_chosen_training_programme { "provider_led" }
      association :last_chosen_lead_provider, factory: :lead_provider
    end

    trait :school_led_last_chosen do
      last_chosen_training_programme { "school_led" }
    end

    trait :local_authority_ab_last_chosen do
      association :last_chosen_appropriate_body, :local_authority, factory: :appropriate_body_period
    end

    trait :national_ab_last_chosen do
      association :last_chosen_appropriate_body, :national, factory: :appropriate_body_period
    end

    trait :teaching_school_hub_ab_last_chosen do
      association :last_chosen_appropriate_body, :teaching_school_hub, factory: :appropriate_body_period
    end

    trait :eligible do
      gias_school { association :gias_school, :eligible, urn: }
    end

    trait :ineligible do
      gias_school { association :gias_school, :open, :in_england, :ineligible, urn: }
    end

    trait :open do
      gias_school { association :gias_school, :open, :in_england, :eligible, urn: }
    end

    trait :section_41 do
      gias_school { association :gias_school, :section_41, urn: }
    end

    trait :not_section_41 do
      gias_school { association :gias_school, :not_section_41, urn: }
    end

    trait :with_administrative_district do
      gias_school { association :gias_school, administrative_district_name: "North Northhamptonshire", urn: }
    end

    trait :with_induction_tutor do
      induction_tutor_name { "Induction Tutor" }
      induction_tutor_email { "induction.tutor@a-very-nice-school.sch.uk" }
    end

    trait :with_unconfirmed_induction_tutor do
      induction_tutor_last_nominated_in { nil }
    end

    trait :without_induction_tutor do
      induction_tutor_name { nil }
      induction_tutor_email { nil }
      induction_tutor_last_nominated_in { nil }
    end

    trait :with_dsi do
      dfe_sign_in_organisation do
        association :dfe_sign_in_organisation, name: gias_school.name, urn:
      end
    end
  end
end
