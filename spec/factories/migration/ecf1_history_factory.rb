FactoryBot.define do
  factory :ecf1_teacher_history, class: "ECF1TeacherHistory" do
    initialize_with { new(user:, ect:, mentor:) }

    transient do
      cohort_year { Random.rand(2020..2119) }
    end

    user { FactoryBot.build(:ecf1_teacher_history_user) }
    ect { nil }
    mentor { nil }

    trait :trnless do
      user { FactoryBot.build(:ecf1_teacher_history_user, trn: nil) }
    end

    trait :ect_with_one_induction_record do
      ect { FactoryBot.build(:ecf1_teacher_history_ect, :one_induction_record, cohort_year:) }
    end

    trait :ect_with_two_induction_record do
      ect { FactoryBot.build(:ecf1_teacher_history_ect, :two_induction_record, cohort_year:) }
    end
  end

  factory :ecf1_teacher_history_user, class: "ECF1TeacherHistory::User" do
    trn { Faker::Number.unique.number(digits: 7) }
    full_name { Faker::FunnyName.two_word_name }
    user_id { SecureRandom.uuid }
    created_at { 12.months.ago }
    updated_at { 6.months.ago }

    initialize_with { new(trn:, full_name:, user_id:, created_at:, updated_at:) }
  end

  factory :ecf1_teacher_history_profile_state_row, class: "ECF1TeacherHistory::ProfileState" do
    state { "active" }
    reason { nil }
    created_at { 12.months.ago }

    initialize_with { new(state:, reason:, created_at:) }
  end

  factory :ecf1_teacher_history_schedule_info, class: "Types::ScheduleInfo" do
    schedule_id { SecureRandom.uuid }
    name { "ECF Standard September" }
    identifier { "ecf-standard-september" }
    cohort_year { Random.rand(2020..2119) }

    initialize_with do
      new(schedule_id:,
          name:,
          identifier:,
          cohort_year:)
    end
  end

  factory :ecf1_teacher_history_training_provider_info, class: "ECF1TeacherHistory::TrainingProviderInfo" do
    sequence(:lead_provider_info) { |n| Types::LeadProviderInfo.new(ecf1_id: SecureRandom.uuid, name: "History Lead Provider #{n}") }
    sequence(:delivery_partner_info) { |n| Types::DeliveryPartnerInfo.new(ecf1_id: SecureRandom.uuid, name: "History Delivery Partner #{n}") }
    cohort_year { Random.rand(2020..2119) }

    initialize_with do
      new(lead_provider_info:,
          delivery_partner_info:,
          cohort_year:)
    end
  end

  factory :ecf1_teacher_history_induction_record_row, class: "ECF1TeacherHistory::InductionRecord" do
    transient do
      full_name { Faker::FunnyName.two_word_name }
    end

    induction_record_id { SecureRandom.uuid }
    cohort_year { Random.rand(2020..2119) }
    start_date { Date.new(cohort_year, 9, 1) }
    end_date { Date.new(cohort_year + 2, 6, 1) }
    created_at { start_date }
    updated_at { 6.months.ago }
    sequence(:school) { |n| Types::SchoolData.new(urn: 100_000 + n, name: "School #{n}") }
    schedule_info { FactoryBot.build(:ecf1_teacher_history_schedule_info, cohort_year:) }
    preferred_identity_email { Faker::Internet.unique.email(name: full_name) }
    mentor_profile_id { SecureRandom.uuid }
    training_status { "active" }
    induction_status { "active" }
    training_programme { "full_induction_programme" }
    training_provider_info { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year:) }
    sequence(:appropriate_body) { |n| Types::AppropriateBodyData.new(ecf1_id: SecureRandom.uuid, name: "History Appropriate body #{n}") }

    initialize_with do
      new(induction_record_id:,
          start_date:,
          end_date:,
          created_at:,
          updated_at:,
          cohort_year:,
          school:,
          schedule_info:,
          preferred_identity_email:,
          mentor_profile_id:,
          training_status:,
          induction_status:,
          training_programme:,
          training_provider_info:,
          appropriate_body:)
    end

    trait :created_at_later_than_start_date do
      created_at { start_date + 2.days }
    end

    trait :start_date_later_than_created_at do
      created_at { start_date - 2.days }
    end

    trait :ongoing do
      end_date { nil }
    end
  end

  factory :ecf1_teacher_history_mentor_at_school_period_row, class: "ECF1TeacherHistory::MentorAtSchoolPeriod" do
    mentor_at_school_period_id { SecureRandom.uuid }
    started_on { Date.new(2023, 9, 1) }
    finished_on { Date.new(2023 + 2, 6, 1) }
    created_at { started_on }
    updated_at { 6.months.ago }
    sequence(:school) { |n| Types::SchoolData.new(urn: 100_000 + n, name: "School #{n}") }
    teacher do
      Types::TeacherData.new(trn: Faker::Number.unique.number(digits: 7),
                             api_mentor_training_record_id: SecureRandom.uuid)
    end

    initialize_with do
      new(mentor_at_school_period_id:,
          started_on:,
          finished_on:,
          created_at:,
          updated_at:,
          school:,
          teacher:)
    end

    trait :created_at_later_than_started_on do
      created_at { started_on + 2.days }
    end

    trait :started_on_later_than_created_at do
      created_at { started_on - 2.days }
    end

    trait :ongoing do
      finished_on { nil }
    end
  end

  factory :ecf1_teacher_history_ect, class: "ECF1TeacherHistory::ECT" do
    transient do
      cohort_year { Random.rand(2020..2119) }
    end

    participant_profile_id { SecureRandom.uuid }
    induction_start_date { Date.new(cohort_year, 9, 1) }
    induction_completion_date { nil }
    created_at { Date.new(cohort_year, 9, 1) }
    updated_at { 6.months.ago }
    states { [FactoryBot.build(:ecf1_teacher_history_profile_state_row)] }
    induction_records { [] }
    mentor_at_school_periods { [] }

    pupil_premium_uplift { false }
    sparsity_uplift { false }
    payments_frozen_cohort_start_year { nil }

    initialize_with do
      new(participant_profile_id:,
          induction_start_date:,
          induction_completion_date:,
          created_at:,
          updated_at:,
          states:,
          induction_records:,
          mentor_at_school_periods:,
          pupil_premium_uplift:,
          sparsity_uplift:,
          payments_frozen_cohort_start_year:)
    end

    trait :one_induction_record do
      induction_records { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, cohort_year:)] }
      mentor_at_school_periods do
        [
          FactoryBot.build(:ecf1_teacher_history_mentor_at_school_period_row,
                           school: induction_records.first.school)
        ]
      end
    end

    trait :two_induction_record do
      induction_records do
        ir1 = FactoryBot.build(:ecf1_teacher_history_induction_record_row, cohort_year:)
        ir2 = FactoryBot.build(:ecf1_teacher_history_induction_record_row,
                               cohort_year:,
                               start_date: ir1.start_date + 90.days,
                               end_date: ir1.end_date + 90.days)
        [ir1, ir2]
      end

      mentor_at_school_periods do
        [
          FactoryBot.build(:ecf1_teacher_history_mentor_at_school_period_row,
                           school: induction_records.first.school),
          FactoryBot.build(:ecf1_teacher_history_mentor_at_school_period_row,
                           school: induction_records.last.school)
        ]
      end
    end
  end

  factory :ecf1_teacher_history_mentor, class: "ECF1TeacherHistory::Mentor" do
    transient do
      cohort_year { Random.rand(2020..2119) }
    end

    participant_profile_id { SecureRandom.uuid }
    mentor_completion_date { nil }
    mentor_completion_reason { nil }
    created_at { Date.new(cohort_year, 9, 1) }
    updated_at { 6.months.ago }
    states { [FactoryBot.build(:ecf1_teacher_history_profile_state_row)] }
    induction_records { [] }

    payments_frozen_cohort_start_year { nil }

    initialize_with do
      new(participant_profile_id:,
          mentor_completion_date:,
          mentor_completion_reason:,
          created_at:,
          updated_at:,
          states:,
          induction_records:,
          payments_frozen_cohort_start_year:)
    end
  end
end
