describe TeacherHistoryConverter::Cleaner::OverrideFirstStartDateForInductionRecordIntroduction do
  subject do
    TeacherHistoryConverter::Cleaner::OverrideFirstStartDateForInductionRecordIntroduction.new(induction_records).induction_records
  end

  let(:second_induction_record) { FactoryBot.build(:ecf1_teacher_history_induction_record_row) }
  let(:induction_records) { [first_induction_record, second_induction_record] }

  context "when there are no induction records" do
    let(:induction_records) { [] }

    it "returns an empty array without crashing" do
      expect(subject).to eql([])
    end
  end

  context "when the first IR start date is 2022-02-09" do
    let(:first_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 2, 9),
        end_date: 6.months.ago.to_date,
        created_at: 2.years.ago
      )
    end

    it "overwrites the first induction record's start date with the created_at date" do
      expect(subject[0].start_date).to eql(Date.new(2021, 9, 1))
    end

    it "doesn't change the second induction record's start date" do
      expect(subject[1].start_date).to eql(second_induction_record.start_date)
    end
  end

  context "when the first IR start date another date 2022-02-10" do
    let(:first_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 2, 10),
        end_date: 6.months.ago.to_date,
        created_at: 2.years.ago
      )
    end

    it "doesn't change the first induction record's start date" do
      expect(subject[0].start_date).to eql(first_induction_record.start_date)
    end

    it "doesn't change the second induction record's start date" do
      expect(subject[1].start_date).to eql(second_induction_record.start_date)
    end
  end
end
