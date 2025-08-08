describe ECTAtSchoolPeriods::Mentorship do
  describe "#current_mentorship_period" do
    subject { described_class.new(mentee).current_mentorship_period }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing mentorship at a school" do
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:) }
      let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor:) }

      it { is_expected.to eq(ongoing_mentorship) }
    end
  end

  describe "#current_mentor" do
    subject { described_class.new(mentee).current_mentor }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing mentorship at a school" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(mentor) }
    end
  end

  describe "#current_mentor_name" do
    subject { described_class.new(mentee).current_mentor_name }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing mentorship at a school" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(Teachers::Name.new(mentor.teacher).full_name) }
    end
  end
end
