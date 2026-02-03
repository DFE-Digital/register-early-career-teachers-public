describe TeacherHistoryConverter::Cleaner do
  let(:induction_records) do
    [
      FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: Date.new(2024, 2, 2), end_date: Date.new(2015, 1, 1)),
      FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: Date.new(2024, 4, 4), end_date: Date.new(2024, 3, 3)),
      FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: Date.new(2024, 5, 5), end_date: Date.new(2024, 5, 5))
    ]
  end

  it "calls both ServiceStartDate and CorruptedDates cleaners" do
    allow(TeacherHistoryConverter::Cleaner::ServiceStartDate).to receive(:new).and_call_original
    allow(TeacherHistoryConverter::Cleaner::CorruptedDates).to receive(:new).and_call_original
    allow(TeacherHistoryConverter::Cleaner::ZeroDay).to receive(:new).and_call_original

    TeacherHistoryConverter::Cleaner.new(induction_records).induction_records

    expect(TeacherHistoryConverter::Cleaner::ServiceStartDate).to have_received(:new).once
    expect(TeacherHistoryConverter::Cleaner::CorruptedDates).to have_received(:new).once
    expect(TeacherHistoryConverter::Cleaner::ZeroDay).to have_received(:new).once
  end

  it "returns a 'cleansed' set of induction records" do
    cleansed_records = TeacherHistoryConverter::Cleaner.new(induction_records).induction_records

    # changes first IR's end date to start date of next IR (TeacherHistoryConverter::Cleaner::ServiceStartDate)
    expect(cleansed_records[0].end_date).to eql(Date.new(2024, 4, 4))

    # converts second IR to a stub (TeacherHistoryConverter::Cleaner::CorruptedDates)
    expect(cleansed_records[1].start_date).to eql(Date.new(2024, 3, 3))
    expect(cleansed_records[1].end_date).to eql(Date.new(2024, 3, 4))

    # converts third IR from 0 to 1 days (TeacherHistoryConverter::Cleaner::ZeroDay)
    expect(cleansed_records[2].start_date).to eql(Date.new(2024, 5, 5))
    expect(cleansed_records[2].end_date).to eql(Date.new(2024, 5, 6))
  end
end
