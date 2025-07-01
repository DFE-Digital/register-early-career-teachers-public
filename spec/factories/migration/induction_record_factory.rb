FactoryBot.define do
  factory :migration_induction_record, class: "Migration::InductionRecord" do
    participant_profile { FactoryBot.create(:migration_participant_profile, :ect) }
    preferred_identity { participant_profile.participant_identity }
    induction_programme { participant_profile.school_cohort.default_induction_programme }
    schedule { participant_profile.schedule }
    induction_status { :active }
    training_status { :active }
    start_date { 1.month.ago }
    end_date { nil }
  end
end
