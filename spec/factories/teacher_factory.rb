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

    trait :early_roll_out_mentor do
      early_roll_out_mentor do
        mentor_became_ineligible_for_funding_on { Date.new(2021, 4, 19) }
        mentor_became_ineligible_for_funding_reason { 'completed_during_early_roll_out' }
      end
    end

    trait :ineligible_for_mentor_funding do
      mentor_became_ineligible_for_funding_on { Time.zone.today }
      mentor_became_ineligible_for_funding_reason do
        %w[completed_declaration_received started_not_completed].sample
      end
    end
  end
end
