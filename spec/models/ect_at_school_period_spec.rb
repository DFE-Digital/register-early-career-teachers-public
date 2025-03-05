describe ECTAtSchoolPeriod do
  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentee) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:mentors).through(:mentorship_periods).source(:mentor) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:ect_at_school_period) }

    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_presence_of(:teacher_id) }

    context "email" do
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.to allow_value("test@example.com").for(:email) }
      it { is_expected.not_to allow_value("invalid_email").for(:email) }
    end

    context "teacher distinct period" do
      let!(:existing_period) { FactoryBot.create(:ect_at_school_period) }
      let(:teacher_id) { existing_period.teacher_id }

      before { subject.valid? }
      subject { FactoryBot.build(:ect_at_school_period, teacher_id:, started_on:, finished_on:) }

      context "when the period has not finished yet" do
        let(:started_on) { existing_period.started_on - 1.year }
        let(:finished_on) { nil }

        context "when the teacher has a sibling ect_at_school_period starting later" do
          it "add an error" do
            expect(subject.errors.messages).to include(base: ["Teacher ECT periods cannot overlap"])
          end
        end
      end

      context "when the period has end date" do
        let(:started_on) { existing_period.finished_on - 1.day }
        let(:finished_on) { started_on + 1.day }

        context "when the teacher has a sibling ect_at_school_period overlapping" do
          it "add an error" do
            expect(subject.errors.messages).to include(base: ["Teacher ECT periods cannot overlap"])
          end
        end
      end
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: "2023-06-01", finished_on: "2024-01-01") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: '2024-01-01', finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }

    describe ".for_teacher" do
      it "returns ect periods only for the specified teacher" do
        expect(described_class.for_teacher(teacher.id)).to match_array([period_1, period_2, period_3])
      end
    end
  end

  describe "#current_mentorship" do
    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { expect(mentee.current_mentorship).to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago)
      end

      it { expect(mentee.current_mentorship).to be_nil }
    end

    context "when the ect has an ongoing mentorship at a school" do
      let!(:old_mentorship) { FactoryBot.create(:mentorship_period, mentee:, mentor:) }
      let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :active, mentee:, mentor:) }

      it "returns the ongoing mentorship period" do
        expect(mentee.current_mentorship).to eq(ongoing_mentorship)
      end
    end
  end

  describe "#current_mentor" do
    let(:mentee) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no mentorships ever" do
      it { expect(mentee.current_mentor).to be_nil }
    end

    context "when the ect has had past mentorships" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:)
      end

      it { expect(mentee.current_mentor).to be_nil }
    end

    context "when the ect has an ongoing mentorship at a school" do
      before do
        FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: 2.years.ago)
        FactoryBot.create(:mentorship_period, :active, mentee:, mentor:, started_on: 1.year.ago)
      end

      it { expect(mentee.current_mentor).to eql(mentor) }
    end
  end

  describe "#siblings" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: "2023-06-01", finished_on: "2024-01-01") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: '2024-01-01', finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }
    let(:ect_at_school_period) { FactoryBot.build(:ect_at_school_period, teacher:, school:, started_on: "2022-01-01", finished_on: "2023-01-01") }

    it "returns ect periods only for the specified instance's teacher excluding the instance" do
      expect(ect_at_school_period.siblings).to match_array([period_1, period_2, period_3])
    end
  end
end
