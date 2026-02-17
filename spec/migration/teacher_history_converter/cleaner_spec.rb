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
      TeacherHistoryConverter::Cleaner::FixFirstStartDate
    ]
  end

  it "calls both ServiceStartDate and CorruptedDates cleaners" do
    cleaner_steps.each { allow(TeacherHistoryConverter::Cleaner::ServiceStartDate).to receive(:new).and_call_original }
    TeacherHistoryConverter::Cleaner.new(induction_records).induction_records
    cleaner_steps.each { expect(TeacherHistoryConverter::Cleaner::ServiceStartDate).to have_received(:new).once }
  end
end
