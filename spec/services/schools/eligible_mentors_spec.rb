RSpec.describe Schools::EligibleMentors do
  subject do
    described_class.new(school).for_ect(ect)
  end

  let(:school) { create(:school) }
  let(:ect) { create(:ect_at_school_period, :active, started_on: 2.years.ago) }

  describe '#for_ect' do
    context "when the school has no active mentors" do
      it { is_expected.to be_empty }
    end

    context "when the school has active mentors registered" do
      let!(:active_mentors) { create_list(:mentor_at_school_period, 2, :active, school:, started_on: 2.years.ago) }

      it "returns those mentors" do
        expect(subject.to_a).to match_array(active_mentors)
      end
    end

    context "when the ect is also a mentor at the school" do
      let!(:mentors_excluding_ect) { create_list(:mentor_at_school_period, 2, :active, school:, started_on: 2.years.ago) }

      before do
        create(:mentor_at_school_period, :active, school:, teacher: ect.teacher, started_on: 2.years.ago)
      end

      it "returns those mentors excluding themself" do
        expect(subject.to_a).to match_array(mentors_excluding_ect)
      end
    end
  end
end
