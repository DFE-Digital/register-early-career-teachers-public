describe TeacherHistoryConverter::MigrationStrategy do
  subject { TeacherHistoryConverter::MigrationStrategy.new(ecf1_teacher_history) }

  let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records) }
  let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records) }

  let(:induction_records_trait) { :concurrent }
  let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, number_of_ect_induction_records, induction_records_trait) }
  let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, number_of_mentor_induction_records, induction_records_trait) }

  let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, ect:, mentor:) }

  [
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 0, overlap: true, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 1, number_of_mentor_induction_records: 0, overlap: true, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 1, overlap: true, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 2, overlap: true, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 2, number_of_mentor_induction_records: 0, overlap: true, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 2, number_of_mentor_induction_records: 2, overlap: true, expected_outcome: :all_induction_records),
    # more than 2, overlapping
    OpenStruct.new(number_of_ect_induction_records: 3, number_of_mentor_induction_records: 0, overlap: true, expected_outcome: :latest_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 3, overlap: true, expected_outcome: :latest_induction_records),
    # more than 2 but not overlapping
    OpenStruct.new(number_of_ect_induction_records: 3, number_of_mentor_induction_records: 0, overlap: false, expected_outcome: :all_induction_records),
    OpenStruct.new(number_of_ect_induction_records: 0, number_of_mentor_induction_records: 3, overlap: false, expected_outcome: :all_induction_records),
  ].each do |test_case|
    context "when there are #{test_case.number_of_mentor_induction_records} mentor induction records and #{test_case.number_of_ect_induction_records} ECT induction records" do
      let(:number_of_ect_induction_records) { test_case.number_of_ect_induction_records }
      let(:number_of_mentor_induction_records) { test_case.number_of_mentor_induction_records }

      let(:induction_records_trait) { test_case.overlap ? :concurrent : :consecutive }

      it "returns #{test_case.expected_outcome}" do
        expect(subject.strategy).to be(test_case.expected_outcome)
      end
    end
  end

  context "when only ect profile is present" do
    let(:mentor) { nil }
    let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

    it "correctly chooses premium mode" do
      expect(subject.strategy).to eq :all_induction_records
    end

    context "when there are more than 2 induction records" do
      context "when the induction records overlap" do
        let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 3) }

        it "does not meet the criteria for premium" do
          expect(subject.strategy).to eq(:latest_induction_records)
        end
      end

      context "when the induction records don't overlap" do
        let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 3, :consecutive) }

        it "meets the criteria for premium" do
          expect(subject.strategy).to eq(:all_induction_records)
        end
      end
    end

    context "when the teacher has completed induction" do
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records, induction_completion_date: 2.months.ago.to_date) }
      let(:ect_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

      it "does not meet the criteria for premium" do
        expect(subject.strategy).to eq(:latest_induction_records)
      end
    end

    context "when the teacher is deferred" do
      let(:states) { [FactoryBot.build(:ecf1_teacher_history_profile_state_row, state: "deferred")] }
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records, states:) }
      let(:ect_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, training_status: "deferred")] }

      it "does not meet the criteria for premium" do
        expect(subject.strategy).to eq(:latest_induction_records)
      end
    end

    context "when the teacher is withdrawn" do
      let(:states) { [FactoryBot.build(:ecf1_teacher_history_profile_state_row, state: "withdrawn")] }
      let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, induction_records: ect_induction_records, states:) }
      let(:ect_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, training_status: "withdrawn")] }

      it "does not meet the criteria for premium" do
        expect(subject.strategy).to eq(:latest_induction_records)
      end
    end
  end

  context "when only mentor profile is present" do
    let(:ect) { nil }
    let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }

    it "correctly chooses premium mode" do
      expect(subject.strategy).to eq :all_induction_records
    end

    context "when there are more than 2 induction records" do
      let(:mentor_induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 3) }

      it "does not meet the criteria for premium" do
        expect(subject.strategy).to eq(:latest_induction_records)
      end
    end

    context "when the teacher is deferred" do
      let(:states) { [FactoryBot.build(:ecf1_teacher_history_profile_state_row, state: "deferred")] }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records, states:) }
      let(:mentor_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, training_status: "deferred")] }

      it "does not meet the criteria for premium" do
        expect(subject.strategy).to eq(:latest_induction_records)
      end
    end

    context "when the teacher is withdrawn" do
      let(:states) { [FactoryBot.build(:ecf1_teacher_history_profile_state_row, state: "withdrawn")] }
      let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, induction_records: mentor_induction_records, states:) }
      let(:mentor_induction_records) { [FactoryBot.build(:ecf1_teacher_history_induction_record_row, training_status: "withdrawn")] }

      it "does not meet the criteria for premium" do
        expect(subject.strategy).to eq(:latest_induction_records)
      end
    end
  end

  context "when both profiles are present" do
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
end
