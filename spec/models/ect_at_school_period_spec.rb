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

    context "appropriate_body_id" do
      context "when appropriate_body_type is 'teaching_school_hub'" do
        before { subject.appropriate_body_type = 'teaching_school_hub' }

        it do
          is_expected.to validate_presence_of(:appropriate_body_id)
                           .with_message('Must contain the id of an AppropriateBody')
        end

        it do
          is_expected.not_to validate_absence_of(:appropriate_body_id)
        end
      end

      context "when appropriate_body_type is not 'teaching_school_hub'" do
        before { subject.appropriate_body_type = 'teaching_induction_panel' }

        it { is_expected.not_to validate_presence_of(:appropriate_body_id) }
        it { is_expected.to validate_absence_of(:appropriate_body_id).with_message('Must be nil') }
      end
    end

    context "appropriate_body_type" do
      subject { FactoryBot.build(:ect_at_school_period) }

      it do
        is_expected.to validate_inclusion_of(:appropriate_body_type)
                         .in_array(%w[teaching_induction_panel teaching_school_hub])
                         .with_message("Must be nil or teaching_induction_panel or teaching_school_hub")
                         .allow_nil
      end

      context "when appropriate_body_id is present" do
        before { subject.appropriate_body_id = 1 }

        it { is_expected.to validate_presence_of(:appropriate_body_type).with_message("Must be 'teaching_school_hub'") }
      end
    end

    context "email" do
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.to allow_value("test@example.com").for(:email) }
      it { is_expected.not_to allow_value("invalid_email").for(:email) }
    end

    context "lead_provider_id" do
      subject { FactoryBot.build(:ect_at_school_period) }

      context "when programme_type is 'provider_led'" do
        before { subject.programme_type = 'provider_led' }

        it do
          is_expected.to validate_presence_of(:lead_provider_id)
                           .with_message('Must contain the id of a LeadProvider')
                           .allow_nil
        end

        it do
          is_expected.not_to validate_absence_of(:lead_provider_id)
        end
      end

      context "when programme_type is not 'provider_led'" do
        before { subject.programme_type = 'school_led' }

        it { is_expected.not_to validate_presence_of(:lead_provider_id) }
        it { is_expected.to validate_absence_of(:lead_provider_id).with_message('Must be nil') }
      end
    end


    describe 'overlapping periods' do
      let(:started_on_message) { 'Start date cannot overlap another Teacher ECT period' }
      let(:finished_on_message) { 'End date cannot overlap another Teacher ECT period' }
      let(:teacher) { FactoryBot.create(:teacher) }

      context '#teacher_distinct_period' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            before do
              FactoryBot.create(:ect_at_school_period, teacher:,
                                started_on: test.existing_period_range.first,
                                finished_on: test.existing_period_range.last)
              period.valid?
            end

            let(:period) do
              FactoryBot.build(:ect_at_school_period, teacher:,
                               started_on: test.new_period_range.first,
                               finished_on: test.new_period_range.last)
            end

            let(:messages) { period.errors.messages }

            it "is #{test.expected_valid ? 'valid' : 'invalid'}" do
              if test.expected_valid
                expect(messages).not_to have_key(:started_on)
                expect(messages).not_to have_key(:finished_on)
              else
                case index
                when 0
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 1
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 2
                  expect(messages).not_to have_key(:started_on)
                  expect(messages[:finished_on]).to include(finished_on_message)
                end
              end
            end

            context "programme_type" do
      subject { FactoryBot.build(:ect_at_school_period) }

      it do
        is_expected.to validate_inclusion_of(:programme_type)
                         .in_array(%w[provider_led school_led])
                         .with_message("Must be provider_led or school_led")
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
