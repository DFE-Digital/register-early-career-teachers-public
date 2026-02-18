describe TeacherHistoryConverter::Cleaner do
  let(:induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 5) }
  let(:cleaner_steps) do
    [
      TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas,
      TeacherHistoryConverter::Cleaner::SchoolFundedFip,
      TeacherHistoryConverter::Cleaner::IndependentNonSection41,
      TeacherHistoryConverter::Cleaner::ServiceStartDate,
      TeacherHistoryConverter::Cleaner::CorruptedDates,
      TeacherHistoryConverter::Cleaner::ZeroDay,
      TeacherHistoryConverter::Cleaner::OverrideFirstStartDateWithCreationDateIfEarlier,
      TeacherHistoryConverter::Cleaner::OverrideFirstStartDateForInductionRecordIntroduction,
      TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate
    ]
  end

  it "calls all of the cleaner steps once" do
    cleaner_steps.each { allow(TeacherHistoryConverter::Cleaner::ServiceStartDate).to receive(:new).and_call_original }
    TeacherHistoryConverter::Cleaner.new(induction_records).induction_records
    cleaner_steps.each { expect(TeacherHistoryConverter::Cleaner::ServiceStartDate).to have_received(:new).once }
  end

  context "when an induction_completion_date is present" do
    let(:induction_completion_date) { Date.new(2026, 1, 2) }

    it "is passed into the 'snip ongoing records to induction completion date' object" do
      allow(TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate).to receive(:new).and_call_original
      TeacherHistoryConverter::Cleaner.new(induction_records, induction_completion_date:).induction_records
      expect(TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate).to have_received(:new).with(induction_records, induction_completion_date:)
    end
  end
end
