describe TeacherHistoryConverter::Cleaner::RemovePostInductionCompletionRecords do
  subject(:cleaner) { described_class.new(raw_induction_records, induction_completion_date:, profile_id:) }

  describe "#induction_records" do
    let(:induction_completion_date) { nil }
    let(:profile_id) { SecureRandom.uuid }
    let(:lead_provider_id) { training_provider_info.lead_provider_info.ecf1_id }
    let(:training_provider_info) { induction_record_1.training_provider_info }

    let(:induction_record_1) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
      )
    end
    let(:induction_record_2) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 3, 15),
        end_date: Date.new(2023, 9, 1),
        created_at: Time.zone.local(2023, 3, 15, 14, 0, 0),
        training_provider_info:
      )
    end
    let(:induction_record_3) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 5, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2022, 5, 1, 12, 0, 0),
        training_provider_info:
      )
    end
    let(:raw_induction_records) { [induction_record_1, induction_record_2, induction_record_3] }

    context "when the induction_completion_date is blank" do
      it "returns all the induction records" do
        expect(cleaner.induction_records).to match raw_induction_records
      end
    end

    context "when the induction_completion_date is set" do
      let(:induction_completion_date) { induction_record_1.end_date }

      context "when the combo check returns true" do
        before do
          combo_checker = instance_double(TeacherHistoryConverter::PostInductionCompletionComboCheck)
          allow(TeacherHistoryConverter::PostInductionCompletionComboCheck).to receive(:new).and_return(combo_checker)
          allow(combo_checker).to receive(:keep?).and_return(true)
        end

        it "does not remove records after the induction_completion_date" do
          expect(cleaner.induction_records).to match raw_induction_records
        end
      end

      context "when the combo check returns false" do
        before do
          combo_checker = instance_double(TeacherHistoryConverter::PostInductionCompletionComboCheck)
          allow(TeacherHistoryConverter::PostInductionCompletionComboCheck).to receive(:new).and_return(combo_checker)
          allow(combo_checker).to receive(:keep?).and_return(false)
        end

        it "remove the records post induction completion date" do
          expect(cleaner.induction_records).to match [induction_record_1]
        end
      end
    end
  end
end
