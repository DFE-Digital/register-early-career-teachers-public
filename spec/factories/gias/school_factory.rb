FactoryBot.define do
  factory(:gias_school, class: GIAS::School) do
    eligible_for_registration
    eligible_for_fip
    induction_eligible
    not_section_41

    local_authority_code { Faker::Number.within(range: 1..999) }
    name { Faker::Educator.primary_school + " (#{urn})" }
    establishment_number { Faker::Number.unique.within(range: 1..9_999) }
    phase_name { "Phase one" }
    urn { Faker::Number.unique.within(range: 10_000..9_999_999) }
    ukprn { Faker::Number.unique.number(digits: 5) }

    # eligibility to be registered in the service
    trait(:eligible_for_registration) do
      open
      in_england

      if [true, false].sample
        eligible_type
      else
        not_eligible_type
        independent_school_type
        section_41
      end
    end

    # cip_only
    trait(:cip_only) do
      cip_only_type
      not_section_41
      [true, false].sample ? eligible_for_cip : funding_ineligible
    end

    trait(:not_cip_only) do
      not_cip_only_type
      [true, false].sample ? eligible_for_fip : funding_ineligible
    end

    # funding_eligibility
    trait(:eligible_for_fip) do
      funding_eligibility { "eligible_for_fip" }
    end

    trait(:eligible_for_cip) do
      funding_eligibility { "eligible_for_cip" }
    end

    trait(:funding_ineligible) do
      funding_eligibility { "ineligible" }
    end

    # induction_eligibility
    trait(:induction_eligible) do
      induction_eligibility { true }
    end

    trait(:induction_ineligible) do
      induction_eligibility { false }
    end

    # section 41 approved
    trait(:section_41) do
      section_41_approved { true }
    end

    trait(:not_section_41) do
      section_41_approved { false }
    end

    # status
    trait(:open) do
      status { %w[open proposed_to_close].sample }
    end

    trait(:not_open) do
      status { %w[closed proposed_to_open].sample }
    end

    # location
    trait(:in_england) do
      in_england { true }
      type_name { GIAS::Types::IN_ENGLAND_TYPES.sample }
    end

    trait(:not_in_england) do
      in_england { false }
      type_name { GIAS::Types::NOT_IN_ENGLAND_TYPES.sample }
    end

    # type code
    trait(:cip_only_type) do
      type_name { GIAS::Types::CIP_ONLY_TYPES.sample }
    end

    trait(:not_cip_only_type) do
      type_name { (GIAS::Types::ALL_TYPES - GIAS::Types::CIP_ONLY_TYPES).sample }
    end

    trait(:eligible_type) do
      type_name { GIAS::Types::ELIGIBLE_TYPES.sample }
    end

    trait(:not_eligible_type) do
      type_name { GIAS::Types::NOT_ELIGIBLE_TYPES.sample }
    end

    trait(:independent_school_type) do
      type_name { GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.sample }
    end

    trait(:state_school_type) do
      type_name { GIAS::Types::STATE_SCHOOL_TYPES.sample }
    end

    trait(:with_school) do
      school { build_school }
    end
  end
end
