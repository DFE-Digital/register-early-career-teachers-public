FactoryBot.define do
  factory(:pending_induction_submission) do
    association :appropriate_body
    sequence(:trn, 3_000_000)
    date_of_birth { Faker::Date.between(from: 80.years.ago, to: 20.years.ago) }
    sequence(:trs_first_name) { |n| "First name #{n}" }
    sequence(:trs_last_name) { |n| "Last name #{n}" }
    trs_induction_status { "None" }
    started_on { 1.year.ago }
    trs_qts_awarded_on { 2.years.ago }
    delete_at { nil }

    trait :starting do
      started_on { 1.year.ago }
      induction_programme { "fip" }
    end

    trait :finishing do
      finished_on { 1.week.ago }
      number_of_terms { 3 }
    end

    trait :marked_for_deletion do
      delete_at { 1.day.ago }
    end

    trait :claimed do
      starting
      marked_for_deletion
    end

    trait :passed do
      marked_for_deletion
      outcome { "pass" }
      started_on { nil }
      finished_on { 1.week.ago }
      number_of_terms { 3 }
    end

    trait :failed do
      marked_for_deletion
      outcome { "fail" }
      started_on { nil }
      finished_on { 1.week.ago }
      number_of_terms { 3 }
    end

    trait :released do
      marked_for_deletion
      started_on { nil }
      finished_on { 1.week.ago }
      number_of_terms { 3 }
    end
  end
end
