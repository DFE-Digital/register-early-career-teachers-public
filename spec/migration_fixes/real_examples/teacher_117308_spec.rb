describe "Real data check for teacher 117308" do
  let!(:teacher) { FactoryBot.create(:teacher, id: 117308) }
  let!(:school_1) { FactoryBot.create(:school, id: 31580) }
  
  let!(:mentor_at_school_period_1) { FactoryBot.create(:mentor_at_school_period, id: 14939, teacher:, school: school_1, started_on: Date.new(2023, 9, 14), finished_on: nil) }
  

  let(:migration_fixes) do
    [
      {
        object_type: "MentorAtSchoolPeriod",
        object_id: 14_939,
        action: "delete",
        attributes: nil
      },
      {
        object_type: "Teacher",
        object_id: 117_308,
        action: "delete",
        attributes: nil
      },
      {
        object_type: "School",
        object_id: 31_580,
        action: "delete",
        attributes: nil
      },
    ]
  end

  let(:processor) { MigrationFixes::Processor.new }

  before do
    migration_fixes.each do |data_change|
      processor.process!(data_change:)
    end
  end

  it "deletes the mentor_at_school_period record" do
    expect {
      mentor_at_school_period_1.reload
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes the teacher record" do
    expect {
      teacher.reload
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "deletes the school record" do
    expect {
      school_1.reload
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
