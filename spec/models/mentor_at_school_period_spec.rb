describe MentorAtSchoolPeriod do
  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:mentor_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:mentor_at_school_periods) }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentor) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:currently_assigned_ects).through(:mentorship_periods).source(:mentee) }
    it { is_expected.to have_many(:currently_assigned_and_transferring_ects).through(:mentorship_periods).source(:mentee) }
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

    describe ".with_partnerships_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: period_2,
                                                         started_on: period_2.started_on,
                                                         finished_on: period_2.finished_on)
      end

      it "returns mentor in training periods only for the specified contract period" do
        expect(described_class.with_partnerships_for_contract_period(training_period.school_partnership.contract_period.id)).to match_array([period_2])
      end
    end

    describe ".with_expressions_of_interest_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :with_only_expression_of_interest,
                          :for_mentor,
                          mentor_at_school_period: period_2,
                          started_on: period_2.started_on,
                          finished_on: period_2.finished_on)
      end

      it "returns mentor in training periods only for the specified contract period" do
        expect(described_class.with_expressions_of_interest_for_contract_period(training_period.expression_of_interest.contract_period.id)).to match_array([period_2])
      end
    end

    describe ".with_expressions_of_interest_for_lead_provider_and_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :with_only_expression_of_interest,
                          :for_mentor,
                          mentor_at_school_period: period_2,
                          started_on: period_2.started_on,
                          finished_on: period_2.finished_on)
      end

      it "returns mentor in training periods only for the specified contract period and lead provider" do
        expect(described_class.with_expressions_of_interest_for_lead_provider_and_contract_period(training_period.expression_of_interest.contract_period.id, training_period.expression_of_interest.lead_provider_id)).to match_array([period_2])
      end
    end
  end

  describe "#currently_assigned_ects" do
    let(:school) { FactoryBot.create(:school) }
    let(:mentor_teacher) { FactoryBot.create(:teacher) }
    let(:ect_teacher) { FactoryBot.create(:teacher) }

    let(:mentor_period) do
      FactoryBot.create(:mentor_at_school_period,
                        school:,
                        teacher: mentor_teacher,
                        started_on: 1.month.ago,
                        finished_on: nil)
    end

    context "when ECT is currently assigned and active at the school" do
      let!(:ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school:,
                          teacher: ect_teacher,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      let!(:mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentor: mentor_period,
                          mentee: ect_period,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      it "returns the currently assigned ECT" do
        assigned_ects = mentor_period.currently_assigned_ects
        expect(assigned_ects).to include(ect_period)
      end
    end

    context "when ECT is assigned but period has ended" do
      let!(:ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school:,
                          teacher: ect_teacher,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      let!(:mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentor: mentor_period,
                          mentee: ect_period,
                          started_on: 1.month.ago,
                          finished_on: 1.week.ago)
      end

      it "returns the ECT (ECT period is ongoing even though mentorship ended)" do
        assigned_ects = mentor_period.currently_assigned_ects
        expect(assigned_ects).to include(ect_period)
      end
    end

    context "when ECT is assigned at different school" do
      let(:different_school) { FactoryBot.create(:school) }

      let!(:ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school: different_school,
                          teacher: ect_teacher,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      let!(:mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentor: mentor_period,
                          mentee: ect_period,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      it "returns the ECT even from different school (association follows mentorship regardless of school)" do
        assigned_ects = mentor_period.currently_assigned_ects
        expect(assigned_ects).to include(ect_period)
      end
    end

    context "with future ECT assignment" do
      let!(:future_ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school:,
                          teacher: FactoryBot.create(:teacher),
                          started_on: 1.week.from_now,
                          finished_on: nil)
      end

      let!(:future_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentor: mentor_period,
                          mentee: future_ect_period,
                          started_on: 1.week.from_now,
                          finished_on: nil)
      end

      it "returns future ECTs (ongoing includes future periods)" do
        assigned_ects = mentor_period.currently_assigned_ects
        expect(assigned_ects).to include(future_ect_period)
      end
    end

    context "when mentorship period is finished but ECT period is ongoing" do
      let!(:finished_mentor_period) do
        FactoryBot.create(:mentor_at_school_period,
                          school:,
                          teacher: FactoryBot.create(:teacher),
                          started_on: 2.months.ago,
                          finished_on: 1.week.ago)
      end

      let!(:ongoing_ect_with_finished_mentorship) do
        FactoryBot.create(:ect_at_school_period,
                          school:,
                          teacher: FactoryBot.create(:teacher),
                          started_on: 2.months.ago,
                          finished_on: nil)
      end

      let!(:finished_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentor: finished_mentor_period,
                          mentee: ongoing_ect_with_finished_mentorship,
                          started_on: 2.months.ago,
                          finished_on: 1.week.ago)
      end

      it "returns ECT even when mentorship has ended (association doesn't filter mentorship status)" do
        assigned_ects = finished_mentor_period.currently_assigned_ects
        expect(assigned_ects).to include(ongoing_ect_with_finished_mentorship)
      end
    end

    context "when ECT period is finished but mentorship period is ongoing" do
      let!(:finished_ect_with_ongoing_mentorship) do
        FactoryBot.create(:ect_at_school_period,
                          school:,
                          teacher: FactoryBot.create(:teacher),
                          started_on: 2.months.ago,
                          finished_on: 1.week.ago)
      end

      let!(:finished_mentor_period_2) do
        FactoryBot.create(:mentor_at_school_period,
                          school:,
                          teacher: FactoryBot.create(:teacher),
                          started_on: 2.months.ago,
                          finished_on: 1.week.ago)
      end

      let!(:ongoing_mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          mentor: finished_mentor_period_2,
                          mentee: finished_ect_with_ongoing_mentorship,
                          started_on: 2.months.ago,
                          finished_on: 1.week.ago)
      end

      it "does not return ECT when ECT period has ended" do
        assigned_ects = finished_mentor_period_2.currently_assigned_ects
        expect(assigned_ects).not_to include(finished_ect_with_ongoing_mentorship)
      end
    end
  end

  describe "#currently_assigned_and_transferring_ects" do
    let!(:mentor_period) do
      FactoryBot.create(:mentor_at_school_period,
                        started_on: 1.month.ago,
                        finished_on: nil)
    end

    context "with future ECT assignment" do
      let!(:future_ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school: mentor_period.school,
                          started_on: 1.week.from_now,
                          finished_on: nil)
      end

      before do
        FactoryBot.create(:mentorship_period,
                          mentor: mentor_period,
                          mentee: future_ect_period,
                          started_on: 1.week.from_now,
                          finished_on: nil)
      end

      it "returns future ECTs assigned to the mentor" do
        assigned_ects = mentor_period.currently_assigned_and_transferring_ects
        expect(assigned_ects).to include(future_ect_period)
      end
    end

    context "when ECT is currently assigned and active at the school" do
      let!(:current_ect_period) do
        FactoryBot.create(:ect_at_school_period,
                          school: mentor_period.school,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      before do
        FactoryBot.create(:mentorship_period,
                          mentor: mentor_period,
                          mentee: current_ect_period,
                          started_on: 1.month.ago,
                          finished_on: nil)
      end

      it "returns the currently assigned ECT" do
        assigned_ects = mentor_period.currently_assigned_and_transferring_ects
        expect(assigned_ects).to include(current_ect_period)
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
