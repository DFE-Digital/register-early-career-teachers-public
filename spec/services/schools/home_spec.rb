describe Schools::Home do
  subject(:service) { described_class.new(school:) }

  let(:school) { FactoryBot.create(:school) }
  let(:ect) { FactoryBot.create(:teacher) }
  let(:mentor) { FactoryBot.create(:teacher, corrected_name: nil) }

  let(:mentor_period) do
    FactoryBot.create(:mentor_at_school_period, :active,
                      school:,
                      teacher: mentor,
                      started_on: 2.years.ago)
  end

  let(:ect_period) do
    FactoryBot.create(:ect_at_school_period, :active,
                      school:,
                      teacher: ect,
                      started_on: 2.years.ago)
  end

  before do
    FactoryBot.create(:training_period, :active,
                      mentor_at_school_period: mentor_period,
                      ect_at_school_period: nil,
                      started_on: 1.year.ago)
    FactoryBot.create(:mentorship_period, :active,
                      mentor: mentor_period,
                      mentee: ect_period,
                      started_on: 1.year.ago)
  end

  describe '#ects_with_mentors' do
    it "returns actively mentored ECTs and their mentors" do
      expect(service.ects_with_mentors).to eq([ect_period])
    end
  end
end
