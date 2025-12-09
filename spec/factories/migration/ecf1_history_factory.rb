FactoryBot.define do
  factory :ecf1_teacher_history_user, class: "ECF1TeacherHistory::User" do
    trn { Faker::Number.unique.number(digits: 7) }
    full_name { Faker::FunnyName.two_word_name }
    user_id { SecureRandom.uuid }
    created_at { Random.rand(12).months.ago }
    updated_at { Random.rand(30).days.ago }

    initialize_with { new(trn:, full_name:, user_id:, created_at:, updated_at:) }
  end

  factory :ecf1_teacher_history_profile_state_row, class: "ECF1TeacherHistory::ProfileStateRow" do
    state { "active" }
    reason { nil }
    created_at { Random.rand(12).months.ago }

    initialize_with { new(state:, reason:, created_at:) }
  end

  factory :ecf1_teacher_history_schedule_info, class: "ECF1TeacherHistory::ScheduleInfo" do
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
    lead_provider_id { SecureRandom.uuid }
    sequence(:lead_provider_name) { |n| "History Lead Provider #{n}" }
    delivery_partner_id { SecureRandom.uuid }
    sequence(:delivery_partner_name) { |n| "History Delivery Partner#{n}" }
    cohort_year { Random.rand(2020..2119) }

    initialize_with do
      new(lead_provider_id:,
          lead_provider_name:,
          delivery_partner_id:,
          delivery_partner_name:,
          cohort_year:)
    end
  end

  factory :ecf1_teacher_history_induction_record_row, class: "ECF1TeacherHistory::InductionRecordRow" do
    transient do
      full_name { Faker::FunnyName.two_word_name }
    end

    induction_record_id { SecureRandom.uuid }
    start_date { Random.rand(12).months.ago }
    end_date { nil }
    created_at { start_date }
    updated_at { Random.rand(30).days.ago }
    cohort_year { start_date.month > 8 ? start_date.year : start_date.year - 1 }
    school_urn { Faker::Number.unique.number(digits: 6).to_s }
    schedule { FactoryBot.build(:ecf1_teacher_history_schedule_info, cohort_year:) }
    preferred_identity_email { Faker::Internet.unique.email(name: full_name) }
    mentor_profile_id { SecureRandom.uuid }
    training_status { "active" }
    induction_status { "active" }
    training_programme { "full_induction_programme" }
    training_provider_info { FactoryBot.build(:ecf1_teacher_history_training_provider_info, cohort_year:) }

    initialize_with do
      new(induction_record_id:,
          start_date:,
          end_date:,
          created_at:,
          updated_at:,
          cohort_year:,
          school_urn:,
          schedule:,
          preferred_identity_email:,
          mentor_profile_id:,
          training_status:,
          induction_status:,
          training_programme:,
          training_provider_info:)
    end
  end

  factory :ecf1_teacher_history_ect, class: "ECF1TeacherHistory::ECT" do
    participant_profile_id { SecureRandom.uuid }
    induction_start_date { Random.rand(12).months.ago }
    induction_completion_date { nil }
    created_at { Random.rand(12).months.ago }
    updated_at { Random.rand(30).days.ago }
    states { [FactoryBot.build(:ecf1_teacher_history_profile_state_row)] }
    induction_records { [FactoryBot.build(:ecf1_teacher_history_induction_record_row)] }

    initialize_with do
      new(participant_profile_id:,
          induction_start_date:,
          induction_completion_date:,
          created_at:,
          updated_at:,
          states:,
          induction_records:)
    end
  end

  factory :ecf1_teacher_history_mentor, class: "ECF1TeacherHistory::Mentor" do
    participant_profile_id { SecureRandom.uuid }
    mentor_completion_date { nil }
    mentor_completion_reason { nil }
    created_at { Random.rand(12).months.ago }
    updated_at { Random.rand(30).days.ago }
    states { [FactoryBot.build(:ecf1_teacher_history_profile_state_row)] }
    induction_records { [FactoryBot.build(:ecf1_teacher_history_induction_record_row)] }

    initialize_with do
      new(participant_profile_id:,
          mentor_completion_date:,
          mentor_completion_reason:,
          created_at:,
          updated_at:,
          states:,
          induction_records:)
    end
  end
end
