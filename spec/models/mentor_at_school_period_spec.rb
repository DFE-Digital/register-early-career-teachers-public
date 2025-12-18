describe MentorAtSchoolPeriod do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: target) }
    let!(:target) { FactoryBot.create(:school) }

    it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
  end

  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:mentor_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:mentor_at_school_periods) }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentor) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:declarations).through(:training_periods) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:currently_assigned_ects).through(:mentorship_periods).source(:mentee) }
  end

  describe "#currently_assigned_ects" do
    subject { mentor.currently_assigned_ects }

    let(:mentor)    { FactoryBot.create(:mentor_at_school_period, started_on: 2.years.ago, finished_on: nil) }
    let(:finished)  { FactoryBot.create(:ect_at_school_period, finished_on: Time.zone.today) }
    let(:finishing) { FactoryBot.create(:ect_at_school_period, finished_on: 1.week.from_now) }
    let(:current)   { FactoryBot.create(:ect_at_school_period, finished_on: nil) }
    let(:upcoming)  { FactoryBot.create(:ect_at_school_period, started_on: 1.week.from_now) }

    before do
      [finished, finishing, current, upcoming].each do |mentee|
        FactoryBot.create(:mentorship_period, mentor:, mentee:)
      end
    end

    it { is_expected.to match_array [current, finishing] }
  end

  describe ".current_or_next_training_period" do
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 1.year.ago) }

    it { is_expected.to have_one(:current_or_next_training_period).class_name("TrainingPeriod") }

    context "when there is a current period" do
      let!(:training_period) { FactoryBot.create(:training_period, :ongoing, :for_mentor, mentor_at_school_period:) }

      it "returns the current training_period" do
        expect(mentor_at_school_period.current_or_next_training_period).to eql(training_period)
      end
    end

    context "when there is a current period and a future period" do
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 1.year.ago, finished_on: 2.weeks.from_now, mentor_at_school_period:) }
      let!(:future_training_period) { FactoryBot.create(:training_period, :for_mentor, started_on: 2.weeks.from_now, finished_on: nil, mentor_at_school_period:) }

      it "returns the current mentor_at_school_period" do
        expect(mentor_at_school_period.current_or_next_training_period).to eql(training_period)
      end
    end

    context "when there is no current period" do
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :finished, mentor_at_school_period:) }

      it "returns nil" do
        expect(mentor_at_school_period.current_or_next_training_period).to be_nil
      end
    end
  end

  describe "leaving/joining training periods" do
    let(:mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        started_on: 2.years.ago
      )
    end
    let!(:most_recent_training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        started_on: 1.year.ago,
        finished_on: 2.weeks.from_now,
        mentor_at_school_period:
      )
    end
    let!(:oldest_training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        started_on: 2.years.ago,
        finished_on: 1.year.ago,
        mentor_at_school_period:
      )
    end

    describe "#earliest_training_period" do
      subject(:earliest_training_period) do
        mentor_at_school_period.earliest_training_period
      end

      it { is_expected.to eql(oldest_training_period) }
    end

    describe "#latest_training_period" do
      subject(:latest_training_period) do
        mentor_at_school_period.latest_training_period
      end

      it { is_expected.to eql(most_recent_training_period) }
    end
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

    describe "overlapping periods" do
      let(:started_on_message) { "Start date cannot overlap another Teacher School Mentor period" }
      let(:finished_on_message) { "End date cannot overlap another Teacher School Mentor period" }
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:school) { FactoryBot.create(:school) }

      describe "#teacher_distinct_period" do
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

  describe "check constraints" do
    subject { FactoryBot.build(:mentor_at_school_period, school:, teacher:, started_on: Date.current, finished_on: Date.current) }

    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher) }

    it "prevents 0 day periods from being written to the database" do
      expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:school_2) { FactoryBot.create(:school) }
    let!(:period_1) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: "2023-01-01", finished_on: "2023-06-01") }
    let!(:period_2) { FactoryBot.create(:mentor_at_school_period, teacher:, school: school_2, started_on: "2023-06-01", finished_on: "2024-01-01") }
    let!(:period_3) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: "2024-01-01", finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: "2023-02-01", finished_on: "2023-07-01") }

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

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:mentor_at_school_period) }

    context "target teacher" do
      let(:target) { instance.teacher }

      it_behaves_like "a declarative touch model", when_changing: %i[email], timestamp_attribute: :api_updated_at
      it_behaves_like "a declarative touch model", when_changing: %i[email], timestamp_attribute: :api_unfunded_mentor_updated_at, conditional_method: :latest_mentor_at_school_period?
    end

    describe "#latest_mentor_at_school_period?", :with_touches do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:latest_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on: 6.months.ago) }
      let!(:previous_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: 1.year.ago, finished_on: 6.months.ago) }
      let(:email_change) { "test1@anyexampleemail.com" }

      context "when updating the email for the latest mentor period" do
        it "touches `api_unfunded_mentor_updated_at`" do
          expect {
            latest_mentor_at_school_period.update!(email: email_change)
            teacher.reload
          }.to change(teacher, :api_unfunded_mentor_updated_at)
        end
      end

      context "when updating the email for a previous mentor period" do
        it "does not touch `api_unfunded_mentor_updated_at`" do
          expect {
            previous_mentor_at_school_period.update!(email: email_change)
            teacher.reload
          }.not_to change(teacher, :api_unfunded_mentor_updated_at)
        end
      end
    end
  end

  describe "#siblings" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:school_2) { FactoryBot.create(:school) }
    let!(:period_1) { FactoryBot.create(:mentor_at_school_period, teacher:, school:, started_on: "2023-01-01", finished_on: "2023-06-01") }
    let!(:period_2) { FactoryBot.create(:mentor_at_school_period, teacher:, school: school_2, started_on: "2023-06-01", finished_on: "2024-01-01") }
    let!(:mentor_at_school_period) { FactoryBot.build(:mentor_at_school_period, teacher:, school: school_2, started_on: "2022-01-01", finished_on: "2023-01-01") }

    it "returns mentor periods for the specified instance's teacher and school excluding the instance" do
      expect(mentor_at_school_period.siblings).to match_array([period_2])
    end
  end

  describe "#reported_leaving_by?" do
    subject(:period) { FactoryBot.create(:mentor_at_school_period, :ongoing, reported_leaving_by_school_id: reporter_id) }

    let(:reporting_school) { FactoryBot.create(:school) }
    let(:other_school) { FactoryBot.create(:school) }

    context "when reported by the given school" do
      let(:reporter_id) { reporting_school.id }

      it "returns true" do
        expect(period.reported_leaving_by?(reporting_school)).to be true
      end
    end

    context "when reported by a different school" do
      let(:reporter_id) { reporting_school.id }

      it "returns false" do
        expect(period.reported_leaving_by?(other_school)).to be false
      end
    end

    context "when not reported" do
      let(:reporter_id) { nil }

      it "returns false" do
        expect(period.reported_leaving_by?(reporting_school)).to be false
      end
    end
  end

  describe "#leaving_reported_for_school?" do
    let(:reporting_school) { FactoryBot.create(:school) }

    context "when leaving in the future and reported by the school" do
      subject(:period) do
        FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                    reported_leaving_by_school_id: reporting_school.id)
      end

      it "returns true" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be true
      end
    end

    context "when finished in the past" do
      subject(:period) do
        FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, finished_on: 1.day.ago,
                                                    reported_leaving_by_school_id: reporting_school.id)
      end

      it "returns false" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be false
      end
    end

    context "when not reported by the school" do
      subject(:period) do
        FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                    reported_leaving_by_school_id: nil)
      end

      it "returns false" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be false
      end
    end

    context "when reported by the school and finished_on is today" do
      subject(:period) do
        FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, finished_on: Time.zone.today,
                                                    reported_leaving_by_school_id: reporting_school.id)
      end

      it "returns true" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be true
      end
    end
  end
end
