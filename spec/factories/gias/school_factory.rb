FactoryBot.define do
  factory(:gias_school, class: GIAS::School) do
    eligible
    not_section_41

    local_authority_code { Faker::Number.within(range: 1..999) }
    name { Faker::Educator.primary_school + " (#{urn})" }
    establishment_number { Faker::Number.unique.within(range: 1..9_999) }
    phase_name { "Phase one" }
    urn { Faker::Number.unique.within(range: 10_000..9_999_999) }
    ukprn { Faker::Number.unique.within(range: 1_000_000..99_999_999).to_s }

    # eligibility to be registered in the service
    trait(:eligible) do
      open
      in_england
      eligible { true }

      if [true, false].sample
        eligible_type
      else
        independent_school_type
        section_41
      end
    end

    trait(:ineligible) do
      not_eligible_type
      eligible { false }
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
