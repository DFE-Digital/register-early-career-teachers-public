RSpec.describe Teachers::CurrentSchools do
  describe '#ect_at' do
    it 'returns the school from the latest ECTAtSchoolPeriod' do
      teacher = FactoryBot.create(:teacher, trn: '1234567')
      school_1 = FactoryBot.create(:school)
      school_2 = FactoryBot.create(:school)

      FactoryBot.create(:gias_school, school: school_1, name: 'school 1')
      FactoryBot.create(:gias_school, school: school_2, name: "school 2")

      FactoryBot.create(:ect_at_school_period, teacher:, school: school_1, created_at: 2.days.ago, started_on: Date.new(2023, 1, 10), finished_on: Date.new(2023, 2, 25))
      FactoryBot.create(:ect_at_school_period, :active, teacher:, school: school_2, created_at: 1.day.ago, started_on: Date.new(2023, 7, 11), finished_on: nil)

      current_schools = described_class.new(trn: teacher.trn)
      expect(current_schools.ect_at.name).to eq('school 2')
    end

    it 'returns nil if teacher is not found' do
      current_schools = described_class.new(trn: 'nonexistent')
      expect(current_schools.ect_at).to be_nil
    end
  end
end
