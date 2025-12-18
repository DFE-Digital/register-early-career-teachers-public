describe Migration::ParticipantProfile, type: :model do
  describe "#previous_payments_frozen_cohort_start_year" do
    subject { participant_profile.previous_payments_frozen_cohort_start_year }

    let(:initial_cohort) { FactoryBot.create(:migration_cohort, start_year: 2023) }
    let(:initial_school_cohort) { FactoryBot.create(:migration_school_cohort, cohort: initial_cohort) }
    let(:current_school_cohort) { initial_school_cohort }

    let(:participant_profile) do
      FactoryBot.create(:migration_participant_profile,
                        :ect,
                        school_cohort: current_school_cohort,
                        cohort_changed_after_payments_frozen:)
    end

    context "when cohort_changed_after_payments_frozen flag is not set" do
      let(:cohort_changed_after_payments_frozen) { nil }

      it { is_expected.to be_nil }
    end

    context "when cohort_changed_after_payments_frozen flag is set" do
      let(:cohort_changed_after_payments_frozen) { true }
      let(:frozen_cohort) { FactoryBot.create(:migration_cohort, :payments_frozen, start_year: 2021) }
      let(:frozen_school_cohort) { FactoryBot.create(:migration_school_cohort, cohort: frozen_cohort) }
      let(:target_cohort) { FactoryBot.create(:migration_cohort, start_year: 2024) }
      let(:target_school_cohort) { FactoryBot.create(:migration_school_cohort, cohort: target_cohort) }

      context "when the participant has induction records in a frozen cohort but not the current" do
        let(:current_school_cohort) { target_school_cohort }

        before do
          FactoryBot.create(:migration_induction_record,
                            participant_profile:,
                            induction_programme: initial_school_cohort.default_induction_programme,
                            start_date: Date.new(2023, 9, 1),
                            end_date: Date.new(2023, 10, 1))
          FactoryBot.create(:migration_induction_record,
                            participant_profile:,
                            induction_programme: frozen_school_cohort.default_induction_programme,
                            start_date: Date.new(2023, 10, 1),
                            end_date: Date.new(2024, 9, 1))
          FactoryBot.create(:migration_induction_record,
                            participant_profile:,
                            induction_programme: target_school_cohort.default_induction_programme,
                            start_date: Date.new(2024, 9, 1),
                            end_date: nil)
        end

        it { is_expected.to eq(2021) }
      end

      context "when the participant has induction records in a frozen cohort including the current" do
        let(:current_school_cohort) { frozen_school_cohort }

        before do
          FactoryBot.create(:migration_induction_record,
                            participant_profile:,
                            induction_programme: frozen_school_cohort.default_induction_programme,
                            start_date: Date.new(2021, 10, 1),
                            end_date: Date.new(2024, 9, 1))

          FactoryBot.create(:migration_induction_record,
                            participant_profile:,
                            induction_programme: target_school_cohort.default_induction_programme,
                            start_date: Date.new(2024, 9, 1),
                            end_date: Date.new(2024, 10, 1))

          FactoryBot.create(:migration_induction_record,
                            participant_profile:,
                            induction_programme: frozen_school_cohort.default_induction_programme,
                            start_date: Date.new(2024, 10, 1),
                            end_date: nil)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#more_than_two_induction_records?" do
    subject { participant_profile.more_than_two_induction_records? }

    let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }

    context "when the participant has 1 induction record" do
      before do
        FactoryBot.create(:migration_induction_record, participant_profile:)
      end

      it { is_expected.to be_falsey }
    end

    context "when the participant has 2 induction record" do
      before do
        FactoryBot.create_list(:migration_induction_record, 2, participant_profile:)
      end

      it { is_expected.to be_falsey }
    end

    context "when the participant has 3 or more induction record" do
      before do
        FactoryBot.create_list(:migration_induction_record, 3, participant_profile:)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe "#two_induction_records_that_overlap?" do
    subject { participant_profile.two_induction_records_that_overlap? }

    let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }

    context "when the participant does not have two induction records" do
      before do
        FactoryBot.create_list(:migration_induction_record, 1, participant_profile:)
      end

      it { is_expected.to be_falsey }
    end

    context "when the participant has two induction records with no overlaping start and end dates" do
      before do
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: 1.week.ago, end_date: Date.yesterday)
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: Date.current, end_date: Date.tomorrow)
      end

      it { is_expected.to be_falsey }
    end

    context "when the participant has two induction records with overlaping start and end dates" do
      before do
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: 1.week.ago, end_date: Date.yesterday)
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: 3.days.ago, end_date: Date.tomorrow)
      end

      it { is_expected.to be_truthy }
    end
  end
end
