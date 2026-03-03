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

    context "when the ECF1TeacherHistory meets premium conditions" do
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history) }

      it { is_expected.to be(:all_induction_records) }
    end

    context "when the ECF1TeacherHistory doesn't meet premium conditions" do
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, :ect_with_two_induction_record) }

      it { is_expected.to be(:latest_induction_records) }
    end
  end

  describe "building ect_at_school_periods" do
    subject(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

    let(:created_at) { 26.months.ago.round }

    let(:induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }
    let(:ect) { FactoryBot.build(:ecf1_teacher_history_ect, created_at:, induction_records:) }
    let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, ect:) }

    it "sets the first ect_at_school_period created_at to the one from the participant_profile" do
      expect(ecf2_teacher_history.ect_at_school_periods[0].created_at).to eql(created_at)
    end

    it "doesn't adjust the subsequent record's created_at" do
      expect(ecf2_teacher_history.ect_at_school_periods[1].created_at).not_to eql(created_at)
    end
  end

  describe "building mentor_at_school_periods" do
    subject(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

    let(:created_at) { 28.months.ago.round }

    let(:induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 2) }
    let(:mentor) { FactoryBot.build(:ecf1_teacher_history_mentor, created_at:, induction_records:) }
    let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, mentor:) }

    it "sets the first ect_at_school_period created_at to the one from the participant_profile" do
      expect(ecf2_teacher_history.mentor_at_school_periods[0].created_at).to eql(created_at)
    end

    it "doesn't adjust the subsequent record's created_at" do
      expect(ecf2_teacher_history.mentor_at_school_periods[1].created_at).not_to eql(created_at)
    end
  end
end
