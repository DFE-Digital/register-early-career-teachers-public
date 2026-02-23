describe TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate do
  subject do
    TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate.new(induction_records, induction_completion_date:).induction_records
  end

  let(:induction_records) { [first_induction_record, second_induction_record] }
  let(:first_induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row) }

  context "when the second induction record isn't ongoing" do
    let(:induction_completion_date) { nil }
    let(:second_induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 3, 3)) }

    it "doesn't change the second induction record's end_date" do
      expect(subject[1].end_date).to eql(second_induction_record.end_date)
    end
  end

  context "when the second induction record is ongoing" do
    let(:second_induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :ongoing, start_date: Date.new(2025, 1, 1)) }

    context "when no induction_completion_date is provided" do
      let(:induction_completion_date) { nil }

      it "doesn't change the second induction record's end_date" do
        expect(subject[1].end_date).to eql(second_induction_record.end_date)
      end
    end

    context "when an induction_completion_date is provided" do
      let(:induction_completion_date) { Date.new(2026, 1, 1) }

      it "changes the seocnd induction record's end_date to the induction_completion_date" do
        expect(subject[1].end_date).to eql(induction_completion_date)
      end
    end
  end
end
