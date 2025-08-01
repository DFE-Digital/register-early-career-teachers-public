RSpec.describe InductionRecordSanitizer do
  describe "#validate!" do
    subject(:sanitizer) { described_class.new(participant_profile:, group_by:) }

    let(:group_by) { :none }
    let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
    let(:cohort) { participant_profile.school_cohort.cohort }
    let(:school) { participant_profile.school_cohort.school }
    let!(:partnership) { FactoryBot.create(:migration_partnership, school:, cohort:) }
    let!(:induction_record) { FactoryBot.create(:migration_induction_record, participant_profile:) }

    it "does not raise an error when the records are correct" do
      expect {
        sanitizer.validate!
      }.not_to raise_error
    end

    context "when group_by is :school" do
      let(:group_by) { :school }
      let!(:induction_record) { FactoryBot.create(:migration_induction_record, participant_profile:, end_date: 1.week.ago, induction_status: :changed) }
      let!(:induction_record_2) { FactoryBot.create(:migration_induction_record, participant_profile:, start_date: 1.week.ago) }

      it "groups the induction records by school" do
        # 1 school group, 2 records
        expect(sanitizer.induction_records.size).to eq 1
        expect(sanitizer.induction_records.values.first.size).to eq 2
      end
    end

    context "when group_by is :provider" do
      let(:group_by) { :provider }
      let(:partnership) { FactoryBot.create(:migration_partnership, school:, cohort:) }
      let(:induction_programme) { FactoryBot.create(:migration_induction_programme, partnership:) }
      let!(:induction_record) { FactoryBot.create(:migration_induction_record, induction_programme:, participant_profile:, end_date: 1.week.ago, induction_status: :changed) }
      let(:partnership_2) { FactoryBot.create(:migration_partnership, school:, cohort:) }
      let(:induction_programme_2) { FactoryBot.create(:migration_induction_programme, partnership: partnership_2) }
      let!(:induction_record_2) { FactoryBot.create(:migration_induction_record, induction_programme: induction_programme_2, participant_profile:, start_date: 1.week.ago) }

      it "groups the induction records by provider" do
        # 2 provider groups, 1 record each
        expect(sanitizer.induction_records.size).to eq 2
        sanitizer.induction_records.each_value do |records|
          expect(records.count).to eq 1
        end
      end
    end

    context "when group_by is not a valid option" do
      let(:group_by) { :banana }

      it "raises an error" do
        expect {
          sanitizer
        }.to raise_error(ArgumentError)
      end
    end

    context "when the profile has no induction records" do
      let!(:induction_record) { nil }

      it "raises a NoInductionRecordsError" do
        expect {
          sanitizer.validate!
        }.to raise_error(InductionRecordSanitizer::NoInductionRecordsError)
      end
    end

    context "when there are multiple records with blank end_date values" do
      let!(:induction_record_2) { FactoryBot.create(:migration_induction_record, participant_profile:) }

      it "raises a MultipleBlankEndDateError" do
        expect {
          sanitizer.validate!
        }.to raise_error(InductionRecordSanitizer::MultipleBlankEndDateError)
      end
    end

    context "when there are multiple records with active induction_status values" do
      let!(:induction_record_2) { FactoryBot.create(:migration_induction_record, participant_profile:, end_date: 1.hour.ago) }

      it "raises a MultipleActiveStatesError" do
        expect {
          sanitizer.validate!
        }.to raise_error(InductionRecordSanitizer::MultipleActiveStatesError)
      end
    end

    context "when an induction record has a start_date that is later than the end_date" do
      let!(:induction_record) { FactoryBot.create(:migration_induction_record, participant_profile:, start_date: 1.hour.ago, end_date: 1.week.ago) }

      it "raises a StartDateAfterEndDateError" do
        expect {
          sanitizer.validate!
        }.to raise_error(InductionRecordSanitizer::StartDateAfterEndDateError)
      end
    end

    context "when the induction records have a start_date that is earlier than the previous records end_date" do
      let!(:induction_record) { FactoryBot.create(:migration_induction_record, participant_profile:, end_date: 1.hour.ago, induction_status: :changed) }
      let!(:induction_record_2) { FactoryBot.create(:migration_induction_record, participant_profile:, start_date: 1.day.ago) }

      it "raises a InvalidDateSequenceError" do
        expect {
          sanitizer.validate!
        }.to raise_error(InductionRecordSanitizer::InvalidDateSequenceError)
      end
    end
  end
end
