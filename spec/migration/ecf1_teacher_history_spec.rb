describe ECF1TeacherHistory do
  let(:trn) { "1234567" }
  let(:full_name) { "Diane Fletcher" }
  let(:ect_induction_record_rows) do
    [
      ECF1TeacherHistory::InductionRecordRow.new(
        start_date: 1.year.ago.to_date,
        end_date: 6.months.ago.to_date
      )
    ]
  end

  let(:mentor_induction_record_rows) do
    [
      ECF1TeacherHistory::InductionRecordRow.new(
        start_date: 3.months.ago.to_date,
        end_date: 1.month.ago.to_date
      )
    ]
  end

  describe "#initialize" do
    subject { ECF1TeacherHistory.new(trn:, full_name:, ect_induction_record_rows:, mentor_induction_record_rows:) }

    it "can be initialized directly with a trn, full_name and an array of induction records" do
      expect(subject.trn).to eql(trn)
      expect(subject.full_name).to eql(full_name)
      expect(subject.ect_induction_record_rows).to eql(ect_induction_record_rows)
      expect(subject.mentor_induction_record_rows).to eql(mentor_induction_record_rows)
    end
  end

  describe "#build" do
    subject { ECF1TeacherHistory.build(user:, teacher_profile:, ect_induction_records:, mentor_induction_records:) }

    let(:user) { FactoryBot.build(:migration_user) }
    let(:teacher_profile) { FactoryBot.build(:migration_teacher_profile) }
    let(:ect_induction_records) { FactoryBot.build_list(:migration_induction_record, 2) }
    let(:mentor_induction_records) { FactoryBot.build_list(:migration_induction_record, 2) }

    it "can be built with ECF1 data" do
      expect(subject.trn).to eql(teacher_profile.trn)
      expect(subject.full_name).to eql(user.full_name)
      expect(subject.ect_induction_record_rows.count).to eql(ect_induction_records.count)
      expect(subject.mentor_induction_record_rows.count).to eql(mentor_induction_records.count)
    end

    describe "setting up induction records correctly" do
      describe "ECT induction records" do
        pending("creates the right number")
        pending("they have the right attributes")
      end

      describe "Mentor induction records" do
        pending("they have the right attributes")
        pending("creates the right number")
      end
    end
  end
end
