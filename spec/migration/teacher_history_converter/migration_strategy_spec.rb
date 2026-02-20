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
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 2, expected_outcome: :latest_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 2, number_of_mentor_induction_records: 0, expected_outcome: :latest_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 2, number_of_mentor_induction_records: 2, expected_outcome: :latest_induction_records),
  ].each do |test_case|
    context "when there are #{test_case.number_of_mentor_induction_records} mentor induction records and #{test_case.number_of_ect_induction_records} ECT induction records" do
      let(:number_of_ect_induction_records) { test_case.number_of_ect_induction_records }
      let(:number_of_mentor_induction_records) { test_case.number_of_mentor_induction_records }

      it "returns #{test_case.expected_outcome}" do
        expect(subject.strategy).to be(test_case.expected_outcome)
      end
    end
  end
end
