describe TeacherHistoryConverter do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  describe "Teacher" do
    describe "setting trs names" do
      let(:ecf1_teacher_history_user) { FactoryBot.build(:ecf1_teacher_history_user, full_name: "Ms Test User") }
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, user: ecf1_teacher_history_user) }

      it "sets trs_first_name and trs_last_name" do
        expect(subject.teacher.trs_first_name).to eql("Test")
        expect(subject.teacher.trs_last_name).to eql("User")
      end
    end

    describe "setting corrected_name" do
      let(:ecf1_teacher_history_user) { FactoryBot.build(:ecf1_teacher_history_user, full_name: "Test User") }
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, user: ecf1_teacher_history_user) }

      it "sets corrected_name" do
        expect(subject.teacher.trs_first_name).to eql("Test")
        expect(subject.teacher.trs_last_name).to eql("User")
        expect(subject.teacher.corrected_name).to eql("Test User")
      end
    end
  end

  describe "Strategy selection" do
    subject { TeacherHistoryConverter.new(ecf1_teacher_history:).migration_mode }

    context "when the ECF1TeacherHistory meets premium conditions", pending: "Add strategy selection logic" do
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, :premium) }

      it { is_expected.to be(:all_induction_records) }
    end

    context "when the ECF1TeacherHistory doesn't meet premium conditions" do
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history) }

      it { is_expected.to be(:latest_induction_records) }
    end
  end
end
