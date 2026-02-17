describe TeacherHistoryConverter::Cleaner::FixFirstStartDate do
  subject do
    TeacherHistoryConverter::Cleaner::FixFirstStartDate.new(induction_records).induction_records
  end

  let(:induction_records) { [first_induction_record, second_induction_record] }
  let(:second_induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row) }

  context "when the first IR start date is later than the created_at" do
    let(:first_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: 1.year.ago.to_date,
        end_date: 6.months.ago.to_date,
        created_at: 2.years.ago
      )
    end

    it "overwrites the first induction record's start date with the created_at date" do
      expect(subject[0].start_date).to eql(first_induction_record.created_at.to_date)
    end

    it "doesn't change the second induction record's start date" do
      expect(subject[1].start_date).to eql(second_induction_record.start_date)
    end
  end

  context "when the first IR start date is earlier than the created_at" do
    let(:first_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: 3.years.ago.to_date,
        end_date: 6.months.ago.to_date,
        created_at: 2.years.ago
      )
    end

    it "overwrites the first induction record's start date with the created_at date" do
      expect(subject[0].start_date).to eql(first_induction_record.start_date)
    end

    it "doesn't change the second induction record's start date" do
      expect(subject[1].start_date).to eql(second_induction_record.start_date)
    end
  end
end
