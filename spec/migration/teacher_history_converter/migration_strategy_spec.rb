describe TeacherHistoryConverter::MigrationStrategy do
  subject { TeacherHistoryConverter::MigrationStrategy.new(ecf1_teacher_history) }

  let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history) }

  it "defaults to economy" do
    expect(subject.strategy).to be(:latest_induction_records)
  end

  describe "Premium" do
    context "when condition X is met" do
      it "returns :all_induction_records"
    end
  end
end
