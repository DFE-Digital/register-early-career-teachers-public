describe ECTAtSchoolPeriod do
  describe "declarative updates" do
    describe "school target" do
      let(:instance) { FactoryBot.create(:ect_at_school_period, :ongoing, school: target) }
      let!(:target) { FactoryBot.create(:school) }

      it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
    end

    describe "teacher target" do
      let(:instance) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: target) }
      let!(:target) { FactoryBot.create(:teacher) }

      it_behaves_like "a declarative metadata model", on_event: %i[create destroy]
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:school_reported_appropriate_body).class_name("AppropriateBodyPeriod").optional }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentee) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:mentors).through(:mentorship_periods).source(:mentor) }
    it { is_expected.to have_many(:events) }

    describe ".current_or_next_training_period" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 1.year.ago) }

      it { is_expected.to have_one(:current_or_next_training_period).class_name("TrainingPeriod") }

      context "when there is a current period" do
        let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }

        it "returns the current training_period" do
          expect(ect_at_school_period.current_or_next_training_period).to eql(training_period)
        end
      end

      context "when there is a current period and a future period" do
        let!(:training_period) { FactoryBot.create(:training_period, started_on: 1.year.ago, finished_on: 2.weeks.from_now, ect_at_school_period:) }
        let!(:future_training_period) { FactoryBot.create(:training_period, started_on: 2.weeks.from_now, finished_on: nil, ect_at_school_period:) }

        it "returns the current ect_at_school_period" do
          expect(ect_at_school_period.current_or_next_training_period).to eql(training_period)
        end
      end

      context "when there is no current period" do
        let!(:training_period) { FactoryBot.create(:training_period, :finished, ect_at_school_period:) }

        it "returns nil" do
          expect(ect_at_school_period.current_or_next_training_period).to be_nil
        end
      end
    end

    describe "leaving/joining training periods" do
      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :ongoing,
          started_on: 2.years.ago
        )
      end
      let!(:most_recent_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          started_on: 1.year.ago,
          finished_on: 2.weeks.from_now,
          ect_at_school_period:
        )
      end
      let!(:oldest_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          ect_at_school_period:
        )
      end

      describe "#earliest_training_period" do
        subject(:earliest_training_period) do
          ect_at_school_period.earliest_training_period
        end

        it { is_expected.to eql(oldest_training_period) }
      end

      describe "#latest_training_period" do
        subject(:latest_training_period) do
          ect_at_school_period.latest_training_period
        end

        it { is_expected.to eql(most_recent_training_period) }
      end
    end

    describe ".current_or_next_mentorship_period" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: nil) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: ect_at_school_period.school) }
      let(:mentorship_started_on) { 3.weeks.ago }
      let(:mentorship_finished_on) { nil }

      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: mentorship_started_on,
          finished_on: mentorship_finished_on
        )
      end

      it { is_expected.to have_one(:current_or_next_mentorship_period).class_name("MentorshipPeriod") }

      context "when there is a current period" do
        it "returns the current mentorship_period" do
          expect(ect_at_school_period.current_or_next_mentorship_period).to eql(mentorship_period)
        end
      end

      context "when there is a current period and a future period" do
        let(:mentorship_finished_on) { 1.week.from_now }

        let!(:future_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :ongoing,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: mentorship_finished_on,
            finished_on: nil
          )
        end

        it "returns the current mentorship_period" do
          expect(ect_at_school_period.current_or_next_mentorship_period).to eql(mentorship_period)
        end
      end

      context "when there is no current period" do
        let(:mentorship_finished_on) { 1.week.ago }

        it "returns nil" do
          expect(ect_at_school_period.current_or_next_mentorship_period).to be_nil
        end
      end
    end

    describe ".latest_mentorship_period" do
      subject { ect_at_school_period.latest_mentorship_period }

      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 1.year.ago) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: ect_at_school_period.school) }
      let(:mentorship_started_on) { 3.weeks.ago }
      let(:mentorship_finished_on) { nil }
      let!(:latest_mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: mentorship_started_on,
          finished_on: mentorship_finished_on
        )
      end

      before do
        # Previous mentorship period.
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: latest_mentorship_period.started_on - 6.months,
          finished_on: latest_mentorship_period.started_on
        )
      end

      it { is_expected.to eq(latest_mentorship_period) }
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_presence_of(:teacher_id) }

    context "school_reported_appropriate_body_id on :register_ect" do
      context ":register_ect context" do
        context "when the school is independent" do
          context "when national ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :national_ab) }

            it { is_expected.to be_valid(:register_ect) }
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid(:register_ect) }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.build(:ect_at_school_period, :independent_school, :local_authority_ab) }

            before { subject.valid?(:register_ect) }

            it do
              expect(subject.errors.messages[:school_reported_appropriate_body_id])
                .to contain_exactly("Must be national or teaching school hub")
            end
          end
        end

        context "when the school is state_funded" do
          subject { FactoryBot.build(:ect_at_school_period, :state_funded_school) }

          context "when national ab chosen" do
            subject { FactoryBot.build(:ect_at_school_period, :state_funded_school, :national_ab) }

            before { subject.valid?(:register_ect) }

            it do
              expect(subject.errors.messages[:school_reported_appropriate_body_id])
                .to contain_exactly("Must be teaching school hub")
            end
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid(:register_ect) }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.build(:ect_at_school_period, :state_funded_school, :local_authority_ab) }

            before { subject.valid?(:register_ect) }

            it do
              expect(subject.errors.messages[:school_reported_appropriate_body_id])
                .to contain_exactly("Must be teaching school hub")
            end
          end
        end
      end

      context "no context" do
        context "when the school is independent" do
          context "when national ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :national_ab) }

            it { is_expected.to be_valid }
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :local_authority_ab) }

            it { is_expected.to be_valid }
          end
        end

        context "when the school is state_funded" do
          subject { FactoryBot.build(:ect_at_school_period, :state_funded_school) }

          context "when national ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :national_ab) }

            it { is_expected.to be_valid }
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :local_authority_ab) }

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context "email" do
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.to allow_value("test@example.com").for(:email) }
      it { is_expected.not_to allow_value("invalid_email").for(:email) }
    end

    describe "overlapping periods" do
      let(:started_on_message) { "Start date cannot overlap another Teacher ECT period" }
      let(:finished_on_message) { "End date cannot overlap another Teacher ECT period" }
      let(:teacher) { FactoryBot.create(:teacher) }

      describe "#teacher_distinct_period" do
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
          end
        end
      end
    end
  end

  describe "check constraints" do
    subject { FactoryBot.build(:ect_at_school_period, school:, teacher:, started_on: Date.current, finished_on: Date.current) }

    let(:school) { FactoryBot.create(:school) }
    let(:teacher) { FactoryBot.create(:teacher) }

    it "prevents 0 day periods from being written to the database" do
      expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: "2023-01-01", finished_on: "2023-06-01") }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: period_1.finished_on, finished_on: "2023-12-11") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: period_2.finished_on, finished_on: nil) }

    describe ".for_school" do
      let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: "2023-02-01", finished_on: "2023-07-01") }

      it "returns only ect periods for the specified school" do
        expect(described_class.for_school(period_1.school_id)).to match_array([period_1, period_3, teacher_2_period])
      end
    end

    describe ".for_teacher" do
      it "returns ect periods only for the specified teacher" do
        expect(described_class.for_teacher(teacher.id)).to match_array([period_1, period_2, period_3])
      end
    end

    describe ".with_partnerships_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period: period_2,
                                                      started_on: period_2.started_on,
                                                      finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period" do
        expect(described_class.with_partnerships_for_contract_period(training_period.school_partnership.contract_period.id)).to match_array([period_2])
      end
    end

    describe ".with_expressions_of_interest_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :with_only_expression_of_interest,
                          :for_ect,
                          ect_at_school_period: period_2,
                          started_on: period_2.started_on,
                          finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period" do
        expect(described_class.with_expressions_of_interest_for_contract_period(training_period.expression_of_interest.contract_period.id)).to match_array([period_2])
      end
    end

    describe ".with_expressions_of_interest_for_lead_provider_and_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :with_only_expression_of_interest,
                          :for_ect,
                          ect_at_school_period: period_2,
                          started_on: period_2.started_on,
                          finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period and lead provider" do
        expect(described_class.with_expressions_of_interest_for_lead_provider_and_contract_period(training_period.expression_of_interest.contract_period.id, training_period.expression_of_interest.lead_provider_id)).to match_array([period_2])
      end
    end

    describe ".unclaimed_by_school_reported_appropriate_body" do
      let(:appropriate_body_period) { FactoryBot.create(:appropriate_body, :teaching_school_hub) }
      let(:other_appropriate_body) { FactoryBot.create(:appropriate_body, :teaching_school_hub) }

      let!(:period_without_induction_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body: appropriate_body_period) }
      let!(:period_with_ongoing_induction_period_for_same_appropriate_body) { FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body: appropriate_body_period) }
      let!(:period_with_ongoing_induction_period_for_different_appropriate_body) { FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body: appropriate_body_period) }
      let!(:period_with_finished_induction_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body: appropriate_body_period) }
      let!(:finished_period) { FactoryBot.create(:ect_at_school_period, :finished, school_reported_appropriate_body: appropriate_body_period) }
      let!(:period_with_different_appropriate_body) { FactoryBot.create(:ect_at_school_period, :ongoing, school_reported_appropriate_body: other_appropriate_body) }

      before do
        FactoryBot.create(:induction_period, :ongoing, appropriate_body_period:, teacher: period_with_ongoing_induction_period_for_same_appropriate_body.teacher)
        FactoryBot.create(:induction_period, :ongoing, appropriate_body_period: other_appropriate_body, teacher: period_with_ongoing_induction_period_for_different_appropriate_body.teacher)
        FactoryBot.create(:induction_period, started_on: 1.year.ago, finished_on: 1.month.ago, teacher: period_with_finished_induction_period.teacher)
      end

      it "returns only current/future periods not claimed by their school_reported_appropriate_body" do
        results = described_class.unclaimed_by_school_reported_appropriate_body

        expect(results).to include(
          period_without_induction_period,
          period_with_finished_induction_period,
          period_with_ongoing_induction_period_for_different_appropriate_body,
          period_with_different_appropriate_body
        )
        expect(results).not_to include(
          period_with_ongoing_induction_period_for_same_appropriate_body,
          finished_period
        )
      end
    end

    describe ".induction_not_completed" do
      let(:teacher_with_passed_induction) { FactoryBot.create(:teacher, :induction_passed) }
      let(:teacher_with_failed_induction) { FactoryBot.create(:teacher, :induction_failed) }

      let!(:period_1) { FactoryBot.create(:ect_at_school_period, :finished, teacher: teacher_with_passed_induction) }
      let!(:period_2) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
      let!(:period_3) { FactoryBot.create(:ect_at_school_period, :finished, teacher: teacher_with_failed_induction) }

      it "returns ect periods where the teacher's induction is not completed" do
        expect(described_class.induction_not_completed).to match_array([period_2])
      end
    end

    describe "claimable and non-claimable scopes" do
      let(:appropriate_body_period) { FactoryBot.create(:appropriate_body, :teaching_school_hub) }
      let(:other_appropriate_body) { FactoryBot.create(:appropriate_body, :teaching_school_hub) }

      let(:teacher_with_qts) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }
      let(:teacher_without_qts) { FactoryBot.create(:teacher, trs_qts_awarded_on: nil) }
      let(:teacher_with_qts_claimed_by_different_ab) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }

      let!(:period_with_qts) do
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher: teacher_with_qts, school_reported_appropriate_body: appropriate_body_period)
      end
      let!(:period_without_qts) do
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher: teacher_without_qts, school_reported_appropriate_body: appropriate_body_period)
      end
      let!(:period_with_qts_claimed_by_different_ab) do
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher: teacher_with_qts_claimed_by_different_ab, school_reported_appropriate_body: appropriate_body_period)
      end

      before do
        FactoryBot.create(:induction_period, :ongoing, appropriate_body_period: other_appropriate_body, teacher: teacher_with_qts_claimed_by_different_ab)
      end

      describe ".without_qts_award" do
        it "returns only periods where the teacher has no QTS award date" do
          results = described_class.without_qts_award

          expect(results).to include(period_without_qts)
          expect(results).not_to include(period_with_qts, period_with_qts_claimed_by_different_ab)
        end
      end

      describe ".claimed_by_different_appropriate_body" do
        it "returns only current/future periods with an active induction period for a different appropriate body" do
          results = described_class.claimed_by_different_appropriate_body

          expect(results).to include(period_with_qts_claimed_by_different_ab)
          expect(results).not_to include(period_with_qts, period_without_qts)
        end
      end

      describe ".claimable" do
        it "returns only current/future periods with QTS and not claimed by a different appropriate body" do
          results = described_class.claimable

          expect(results).to include(period_with_qts)
          expect(results).not_to include(period_without_qts, period_with_qts_claimed_by_different_ab)
        end
      end
    end
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:ect_at_school_period) }

    context "target teacher" do
      let(:target) { instance.teacher }

      it_behaves_like "a declarative touch model", when_changing: %i[email], timestamp_attribute: :api_updated_at
    end
  end

  describe "#siblings" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: "2022-12-01", finished_on: "2023-06-01") }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: period_1.finished_on, finished_on: "2024-01-01") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: period_2.finished_on, finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: "2023-02-01", finished_on: "2023-07-01") }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: "2022-01-01", finished_on: period_1.started_on) }

    it "returns ect periods only for the specified instance's teacher excluding the instance" do
      expect(ect_at_school_period.siblings).to match_array([period_1, period_2, period_3])
    end
  end

  describe "#reported_leaving_by?" do
    subject(:period) { FactoryBot.create(:ect_at_school_period, :ongoing, reported_leaving_by_school_id: reporter_id) }

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
        FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                 reported_leaving_by_school_id: reporting_school.id)
      end

      it "returns true" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be true
      end
    end

    context "when finished in the past" do
      subject(:period) do
        FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.day.ago,
                                                 reported_leaving_by_school_id: reporting_school.id)
      end

      it "returns false" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be false
      end
    end

    context "when not reported by the school" do
      subject(:period) do
        FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                 reported_leaving_by_school_id: nil)
      end

      it "returns false" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be false
      end
    end

    context "when reported by the school and finished_on is today" do
      subject(:period) do
        FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: Time.zone.today,
                                                 reported_leaving_by_school_id: reporting_school.id)
      end

      it "returns true" do
        expect(period.leaving_reported_for_school?(reporting_school)).to be true
      end
    end
  end
end
