describe TeacherHistoryConverter do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  describe "Teacher" do
    describe "setting corrected_name" do
      let(:ecf1_teacher_history_user) { FactoryBot.build(:ecf1_teacher_history_user, full_name: "Test User") }
      let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history, user: ecf1_teacher_history_user) }

      it "selects the user updated at timestamp" do
        expect(subject.teacher_row.trs_first_name).to eql("Test")
        expect(subject.teacher_row.trs_last_name).to eql("User")
        expect(subject.teacher_row.corrected_name).to eql("Test User")
      end
    end
  end
end
