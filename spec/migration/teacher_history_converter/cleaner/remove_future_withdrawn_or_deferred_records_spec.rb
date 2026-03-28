describe TeacherHistoryConverter::Cleaner::RemoveFutureWithdrawnOrDeferredRecords do
  subject { cleaner.induction_records }

  let(:cleaner) { TeacherHistoryConverter::Cleaner::RemoveFutureWithdrawnOrDeferredRecords.new(induction_records) }

  let(:induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 5) << test_case }

  context "when an induction record is active and in the future" do
    let(:test_case) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :active, :future) }

    it "is present" do
      expect(subject).to include(test_case)
    end
  end

  context "when an induction record is deferred and in the past" do
    let(:test_case) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :deferred) }

    it "is present" do
      expect(subject).to include(test_case)
    end
  end

  context "when an induction record is withdrawn and in the past" do
    let(:test_case) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :withdrawn) }

    it "is present" do
      expect(subject).to include(test_case)
    end
  end

  context "when an induction record is deferred and in the future" do
    let(:test_case) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :deferred, :future) }

    it "is removed" do
      expect(subject).not_to include(test_case)
    end
  end

  context "when an induction record is withdrawn and in the future" do
    let(:test_case) { FactoryBot.build(:ecf1_teacher_history_induction_record_row, :withdrawn, :future) }

    it "is removed" do
      expect(subject).not_to include(test_case)
    end
  end
end
