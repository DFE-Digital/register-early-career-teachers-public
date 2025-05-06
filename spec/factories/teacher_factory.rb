FactoryBot.define do
  factory(:teacher) do
    sequence(:trn, 1_000_000)
    sequence(:trs_first_name) { |n| "First name #{n}" }
    sequence(:trs_last_name) { |n| "Last name #{n}" }

    trait :with_corrected_name do
      corrected_name { [trs_first_name, Faker::Name.middle_name, trs_last_name].join(' ') }
    end

    trait :deactivated_in_trs do
      trs_deactivated { true }
    end

    trait :ineligible_for_mentor_funding do
      mentor_became_ineligible_for_funding_on { Time.zone.today }
      mentor_became_ineligible_for_funding_reason do
        %w[
          completed_declaration_received
          completed_during_early_roll_out
          started_not_completed
        ].sample
      end
    end
  end
end
