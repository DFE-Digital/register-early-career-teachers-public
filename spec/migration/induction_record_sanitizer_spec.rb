RSpec.describe InductionRecordSanitizer do
  subject { described_class.new(participant_profile:) }

  let(:participant_profile) { FactoryBot.create(:migration_participant_profile, :ect) }

  describe "#validate!" do
    context "when there is only one record with blank end_date" do
      before do
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: Time.zone.parse("2023-01-01 09:00:00"), end_date: nil, induction_status: :active)
      end

      it "does not modify the record and validates successfully" do
        original_end_date = participant_profile.induction_records.first.end_date

        expect { subject.validate! }.not_to raise_error
        expect(subject.first.end_date).to eq(original_end_date)
      end
    end

    context "when there are multiple records with mixed blank and set end_dates" do
      let!(:first_record) do
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: Time.zone.parse("2023-01-01 09:00:00"), end_date: Time.zone.parse("2023-05-01 09:00:00"), induction_status: :changed)
      end

      let!(:second_record) do
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: Time.zone.parse("2023-05-01 09:00:00"), end_date: nil, induction_status: :changed)
      end

      let!(:third_record) do
        FactoryBot.create(:migration_induction_record, participant_profile:, start_date: Time.zone.parse("2023-09-01 09:00:00"), end_date: nil, induction_status: :active)
      end

      it "automatically fixes multiple blank end dates during validation" do
        expect { subject.validate! }.not_to raise_error

        in_memory_induction_records = subject.to_a

        expect(in_memory_induction_records[0].end_date).to eq(first_record.end_date)
        expect(in_memory_induction_records[1].end_date).to eq(third_record.start_date)
        expect(in_memory_induction_records[2].end_date).to be_nil
      end

      it "does not persists fixes to database" do
        subject.validate!
        expect(second_record.reload.end_date).to be_nil
      end
    end
  end
end
