describe TeacherHistoryConverter::Cleaner::CorruptedDates do
  subject do
    TeacherHistoryConverter::Cleaner::CorruptedDates.new(induction_records).induction_records
  end

  let(:induction_records) { Array.wrap(induction_record) }

  context "when the dates are the right way round" do
    let(:induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: 3.years.ago.to_date,
        end_date: 2.years.ago.to_date
      )
    end

    it "doesn't adjust the dates" do
      expect(subject).to eql(induction_records)
    end
  end

  context "when the end date is null" do
    let(:induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: 3.years.ago.to_date,
        end_date: nil
      )
    end

    it "doesn't adjust the dates" do
      expect(subject).to eql(induction_records)
    end
  end

  context "when the dates are corrupted (inverted)" do
    let(:induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: 2.years.ago.to_date,
        end_date: 3.years.ago.to_date
      )
    end

    it "doesn't adjust the dates" do
      adjusted_induction_record = induction_record.dup
      adjusted_induction_record.start_date = induction_record.end_date
      adjusted_induction_record.end_date = induction_record.end_date + 1.day

      expect(subject[0].start_date).to eql(3.years.ago.to_date)
      expect(subject[0].end_date).to eql(3.years.ago.to_date + 1.day)
    end
  end
end
