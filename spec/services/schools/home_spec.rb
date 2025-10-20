RSpec.describe Schools::Home do
  subject(:service) { described_class.new(school:) }

  let(:school) { FactoryBot.create(:school) }
  let(:ect) { FactoryBot.create(:teacher) }
  let(:mentor) { FactoryBot.create(:teacher, corrected_name: nil) }

  let(:mentor_period) do
    FactoryBot.create(:mentor_at_school_period, :ongoing,
      school:,
      teacher: mentor,
      started_on: 2.years.ago)
  end

  let(:ect_period) do
    FactoryBot.create(:ect_at_school_period, :ongoing,
      school:,
      teacher: ect,
      started_on: 2.years.ago)
  end

  before do
    FactoryBot.create(:training_period, :ongoing,
      mentor_at_school_period: mentor_period,
      ect_at_school_period: nil,
      started_on: 1.year.ago)

    FactoryBot.create(:mentorship_period,
      mentor: mentor_period,
      mentee: ect_period,
      started_on: 2.years.ago,
      finished_on: 1.year.ago)
    FactoryBot.create(:mentorship_period, :ongoing,
      mentor: mentor_period,
      mentee: ect_period,
      started_on: 1.year.ago)
  end

  describe "#ects_with_mentors" do
    it "returns actively mentored ECTs and their mentors" do
      expect(service.ects_with_mentors).to eq([ect_period])
    end
  end

  describe "#mentors_with_ects" do
    it "returns registered mentors" do
      expect(service.mentors_with_ects).to eq([mentor_period])
    end
  end
end
