RSpec.describe InductionRecordSanitizer do
  describe "#validate!" do
    subject(:sanitizer) { described_class.new(participant_profile:, group_by:) }

    let(:group_by) { :none }
    let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
    let!(:induction_record) { FactoryBot.create(:migration_induction_record, participant_profile:) }

    it "does not raise an error when the records are correct" do
      expect {
        sanitizer.validate!
      }.not_to raise_error
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
