RSpec.describe ECTAtSchoolPeriods::Mentorship do
  subject(:service) { described_class.new(mentee) }

  let(:school) { FactoryBot.create(:school) }
  let(:mentee) { FactoryBot.create(:ect_at_school_period, :unfinished, school:, started_on: 3.years.ago) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school:, started_on: 3.years.ago) }
  let(:old_mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school:, started_on: 3.years.ago) }

  describe "#current_or_next_mentorship_period" do
    subject(:current_or_next_mentorship_period) do
      service.current_or_next_mentorship_period
    end

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
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago) }
      let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago) }

      it { is_expected.to eq(ongoing_mentorship) }
    end
  end

  describe "#upcoming_mentorship_periods" do
    subject(:upcoming_mentorship_periods) do
      service.upcoming_mentorship_periods
    end

    context "when the ECT has no mentorships" do
      it { is_expected.to be_empty }
    end

    context "when the ECT has past mentorships" do
      let!(:mentorship) do
        FactoryBot.create(
          :mentorship_period,
          mentee:,
          mentor:,
          started_on: 1.year.ago,
          finished_on: 1.week.ago
        )
      end

      it { is_expected.to be_empty }
    end

    context "when the ECT has an ongoing mentorship" do
      let!(:mentorship) do
        FactoryBot.create(
          :mentorship_period,
          :unfinished,
          mentee:,
          mentor:,
          started_on: 1.year.ago
        )
      end

      it { is_expected.to be_empty }
    end

    context "when the ECT has upcoming mentorships" do
      let!(:upcoming_mentorship) do
        FactoryBot.create(
          :mentorship_period,
          mentee:,
          mentor:,
          started_on: 1.week.from_now,
          finished_on: 6.months.from_now
        )
      end
      let!(:another_upcoming_mentorship) do
        FactoryBot.create(
          :mentorship_period,
          :unfinished,
          mentee:,
          mentor:,
          started_on: 7.months.from_now
        )
      end

      it { is_expected.to contain_exactly(upcoming_mentorship, another_upcoming_mentorship) }
    end
  end

  describe "#current_mentor" do
    subject(:current_mentor) { service.current_mentor }

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
        FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(mentor) }
    end
  end

  describe "#current_mentor_name" do
    subject(:current_mentor_name) { service.current_mentor_name }

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
        FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(Teachers::Name.new(mentor.teacher).full_name) }
    end
  end

  describe "#latest_mentorship_period" do
    subject(:latest_mentorship_period) { service.latest_mentorship_period }

    context "when the ect has had no mentorships ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past mentorships" do
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_mentorship) }
    end

    context "when the ect has an ongoing mentorship at the school" do
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago) }
      let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago) }

      it { is_expected.to eq(ongoing_mentorship) }
    end
  end

  describe "#latest_mentor" do
    subject(:latest_mentor) { service.latest_mentor }

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
        FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(mentor) }
    end
  end

  describe "#latest_mentor_name" do
    subject(:latest_mentor_name) { service.latest_mentor_name }

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
        FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { is_expected.to eql(Teachers::Name.new(mentor.teacher).full_name) }
    end
  end
end
