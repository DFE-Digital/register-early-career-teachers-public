describe ECTAtSchoolPeriods::Mentorship do
  describe "#current_mentorship_period" do
    subject { described_class.new(mentee).current_mentorship_period }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

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
      let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :active, mentee:, mentor:) }

      it { is_expected.to eq(ongoing_mentorship) }
    end
  end

  describe "#current_mentor" do
    subject { described_class.new(mentee).current_mentor }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

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
        FactoryBot.create(:mentorship_period, :active, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(mentor) }
    end
  end

  describe "#current_mentor_name" do
    subject { described_class.new(mentee).current_mentor_name }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

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
        FactoryBot.create(:mentorship_period, :active, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(Teachers::Name.new(mentor.teacher).full_name) }
    end
  end

  describe "#latest_mentorship_period" do
    subject { described_class.new(mentee).latest_mentorship_period }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_mentorship) }
    end

    context "when the ect has an ongoing mentorship at the school" do
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:) }
      let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :active, mentee:, mentor:) }

      it { is_expected.to eq(ongoing_mentorship) }
    end
  end

  describe "#latest_mentor" do
    subject { described_class.new(mentee).latest_mentor }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
    let(:old_mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor: old_mentor, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eq(mentor) }
    end

    context "when the ect has an ongoing mentorship at a school" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor: old_mentor, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, :active, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(mentor) }
    end
  end

  describe "#latest_mentor_name" do
    subject { described_class.new(mentee).latest_mentor_name }

    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
    let(:old_mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor: old_mentor, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eq(Teachers::Name.new(mentor.teacher).full_name) }
    end

    context "when the ect has an ongoing mentorship at a school" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor: old_mentor, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, :active, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(Teachers::Name.new(mentor.teacher).full_name) }
    end
  end
end
