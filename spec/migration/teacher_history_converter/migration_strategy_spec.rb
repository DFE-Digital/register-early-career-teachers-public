describe TeacherHistoryConverter::MigrationStrategy do
  subject { TeacherHistoryConverter::MigrationStrategy.new(ecf1_teacher_history) }

  let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records) }
  let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records) }

  let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, number_of_ect_induction_records) }
  let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, number_of_mentor_induction_records) }

  let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, ect:, mentor:) }

  [
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 0, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 1, number_of_mentor_induction_records: 0, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 1, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 2, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 2, number_of_mentor_induction_records: 0, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 2, number_of_mentor_induction_records: 2, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 3, number_of_mentor_induction_records: 0, expected_outcome: :latest_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 3, expected_outcome: :latest_induction_records),
  ].each do |test_case|
    context "when there are #{test_case.number_of_mentor_induction_records} mentor induction records and #{test_case.number_of_ect_induction_records} ECT induction records" do
      let(:number_of_ect_induction_records) { test_case.number_of_ect_induction_records }
      let(:number_of_mentor_induction_records) { test_case.number_of_mentor_induction_records }

      it "returns #{test_case.expected_outcome}" do
        expect(subject.strategy).to be(test_case.expected_outcome)
      end
    end
  end

  context "when the teacher has completed induction" do
    let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records, induction_completion_date: 2.months.ago.to_date) }
    let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }
    let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

    it "does not meet the criteria for premium" do
      expect(subject.strategy).to eq(:latest_induction_records)
    end
  end

  context "when the teacher is deferred" do
    let(:states) { [FactoryBot.build(:ecf1_teacher_history_profile_state_row, state: "deferred")] }
    let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records, states:) }
    let(:ect_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, training_status: "deferred")] }
    let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

    it "does not meet the criteria for premium" do
      expect(subject.strategy).to eq(:latest_induction_records)
    end
  end

  context "when the teacher is withdrawn" do
    let(:states) { [FactoryBot.build(:ecf1_teacher_history_profile_state_row, state: "withdrawn")] }
    let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records, states:) }
    let(:mentor_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, training_status: "withdrawn")] }
    let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

    it "does not meet the criteria for premium" do
      expect(subject.strategy).to eq(:latest_induction_records)
    end
  end

  context "when the teacher dates in the wrong order" do
    let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records) }
    let(:ect_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date: 1.week.ago, end_date: 1.month.ago)] }
    let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

    it "does not meet the criteria for premium" do
      expect(subject.strategy).to eq(:latest_induction_records)
    end
  end
end
