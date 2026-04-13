describe TeacherHistoryConverter::MigrationStrategy do
  subject { TeacherHistoryConverter::MigrationStrategy.new(ecf1_teacher_history) }

  let(:ecf1_teacher_history) { FactoryBot.build(:ecf1_teacher_history) }

  it "returns :all_induction_records" do
    expect(subject.strategy).to eq(:all_induction_records)
  end
end
