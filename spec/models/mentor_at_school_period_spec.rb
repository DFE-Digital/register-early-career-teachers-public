describe MentorAtSchoolPeriod do
  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:mentor_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:mentor_at_school_periods) }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentor) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:currently_assigned_ects).through(:mentorship_periods).source(:mentee) }
  end

  describe "validations" do
    subject { FactoryBot.build(:mentor_at_school_period) }

    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_presence_of(:teacher_id) }

    context "email" do
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.to allow_value("test@example.com").for(:email) }
      it { is_expected.not_to allow_value("invalid_email").for(:email) }
    end

    describe 'overlapping periods' do
      let(:started_on_message) { 'Start date cannot overlap another Teacher School Mentor period' }
      let(:finished_on_message) { 'End date cannot overlap another Teacher School Mentor period' }
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:school) { FactoryBot.create(:school) }

      context '#teacher_distinct_period' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            before do
              FactoryBot.create(:mentor_at_school_period, teacher:, school:,
                                                          started_on: test.existing_period_range.first,
                                                          finished_on: test.existing_period_range.last)
              period.valid?
            end

            let(:period) do
              FactoryBot.build(:mentor_at_school_period, teacher:, school:,
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
          end
        end
      end
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:school_2) { FactoryBot.create(:school) }
    let!(:period_1) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:mentor_at_school_period, teacher:, school: school_2, started_on: "2023-06-01", finished_on: "2024-01-01") }
    let!(:period_3) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: '2024-01-01', finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }

    describe ".for_school" do
      it "returns mentor periods only for the specified school" do
        expect(described_class.for_school(school_2.id)).to match_array([period_2])
      end
    end

    describe ".for_teacher" do
      it "returns mentor periods only for the specified teacher" do
        expect(described_class.for_teacher(teacher.id)).to match_array([period_1, period_2, period_3])
      end
    end

    describe ".for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: period_2,
                                                         started_on: period_2.started_on,
                                                         finished_on: period_2.finished_on)
      end

      it "returns mentor in training periods only for the specified contract period" do
        expect(described_class.for_contract_period(training_period.school_partnership.contract_period.id)).to match_array([period_2])
      end
    end
  end

  describe "#siblings" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:school_2) { FactoryBot.create(:school) }
    let!(:period_1) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:mentor_at_school_period, teacher:, school: school_2, started_on: "2023-06-01", finished_on: "2024-01-01") }
    let!(:mentor_at_school_period) { FactoryBot.build(:mentor_at_school_period, teacher:, school: school_2, started_on: "2022-01-01", finished_on: "2023-01-01") }

    it "returns mentor periods for the specified instance's teacher and school excluding the instance" do
      expect(mentor_at_school_period.siblings).to match_array([period_2])
    end
  end
end
