FactoryBot.define do
  factory(:gias_school, class: GIAS::School) do
    eligible_for_registration
    eligible_for_fip
    induction_eligible

    easting { Faker::Number.within(range: 0..700_000) }
    local_authority_code { Faker::Number.within(range: 1..999) }
    name { Faker::Educator.primary_school + " (#{urn})" }
    northing { Faker::Number.within(range: 0..1_300_000) }
    establishment_number { Faker::Number.unique.within(range: 1..9_999) }
    phase_name { "Phase one" }
    type_name { GIAS::Types.type_name_for(type_code) }
    urn { Faker::Number.unique.within(range: 10_000..9_999_999) }

    # eligibility to be registered in the service
    trait(:eligible_for_registration) do
      open
      in_england

      if [true, false].sample
        eligible_type_code
        not_section_41
      else
        not_eligible_type_code
        section_41
      end
    end

    # cip_only
    trait(:cip_only) do
      cip_only_type_code
      [true, false].sample ? eligible_for_cip : funding_ineligible
    end

    trait(:not_cip_only) do
      not_cip_only_type_code
      [true, false].sample ? eligible_for_fip : funding_ineligible
    end

    # funding_eligibility
    trait(:eligible_for_fip) do
      funding_eligibility { "eligible_for_fip" }
    end

    trait(:eligible_for_cip) do
      cip_only_type_code
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
      administrative_district_name { "London" }
    end

    trait(:not_in_england) do
      in_england { false }
      administrative_district_name { "Cardiff" }
    end

    # type code
    trait(:cip_only_type_code) do
      type_code { GIAS::Types::CIP_ONLY_TYPE_CODES.sample }
    end

    trait(:not_cip_only_type_code) do
      type_code { (GIAS::Types::ALL_TYPE_CODES - GIAS::Types::CIP_ONLY_TYPE_CODES).sample }
    end

    trait(:eligible_type_code) do
      type_code { GIAS::Types::ELIGIBLE_TYPE_CODES.sample }
    end

    trait(:not_eligible_type_code) do
      type_code { (GIAS::Types::ALL_TYPE_CODES - GIAS::Types::ELIGIBLE_TYPE_CODES).sample }
    end
  end
end
