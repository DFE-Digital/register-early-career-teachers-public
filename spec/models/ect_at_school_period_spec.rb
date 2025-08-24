describe ECTAtSchoolPeriod do
  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:school_reported_appropriate_body).class_name('AppropriateBody').optional }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentee) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:mentors).through(:mentorship_periods).source(:mentor) }
    it { is_expected.to have_many(:events) }

    describe '.current_training_period' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }

      it { is_expected.to have_one(:current_training_period).class_name('TrainingPeriod') }

      context 'when there is a current period' do
        let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }

        it 'returns the current training_period' do
          expect(ect_at_school_period.current_training_period).to eql(training_period)
        end
      end

      context 'when there is no current period' do
        let!(:training_period) { FactoryBot.create(:training_period, :finished, ect_at_school_period:) }

        it 'returns nil' do
          expect(ect_at_school_period.current_training_period).to be_nil
        end
      end
    end

    describe '.current_mentorship_period' do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
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

      it { is_expected.to have_one(:current_mentorship_period).class_name('MentorshipPeriod') }

      context 'when there is a current period' do
        it 'returns the current mentorship_period' do
          expect(ect_at_school_period.current_mentorship_period).to eql(mentorship_period)
        end
      end

      context 'when there is a current period and a future period' do
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

        it 'returns the current mentorship_period' do
          expect(ect_at_school_period.current_mentorship_period).to eql(mentorship_period)
        end
      end

      context 'when there is no current period' do
        let(:mentorship_finished_on) { 1.week.ago }

        it 'returns nil' do
          expect(ect_at_school_period.current_training_period).to be_nil
        end
      end
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
                .to contain_exactly('Must be national or teaching school hub')
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
                .to contain_exactly('Must be teaching school hub')
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
                .to contain_exactly('Must be teaching school hub')
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
          end
        end
      end
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: period_1.finished_on, finished_on: "2023-12-11") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: period_2.finished_on, finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }

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

    describe ".visible_for_school" do
      let(:school_a) { FactoryBot.create(:school) }
      let(:school_b) { FactoryBot.create(:school) }
      let(:transition_teacher) { FactoryBot.create(:teacher) }

      context "when ECT has ongoing period at one school" do
        let!(:ongoing_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: 2.months.ago,
                            finished_on: nil)
        end

        it "shows ongoing period for the correct school" do
          visible_periods = described_class.visible_for_school(school_a)
          expect(visible_periods).to include(ongoing_period)
        end

        it "does not show period for different school" do
          visible_periods = described_class.visible_for_school(school_b)
          expect(visible_periods).not_to include(ongoing_period)
        end
      end

      context "when ECT has future period at a school" do
        let!(:future_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: 1.week.from_now,
                            finished_on: nil)
        end

        it "shows future period for the school even before start date" do
          visible_periods = described_class.visible_for_school(school_a)
          expect(visible_periods).to include(future_period)
        end

        it "does not show future period for different school" do
          visible_periods = described_class.visible_for_school(school_b)
          expect(visible_periods).not_to include(future_period)
        end
      end

      context "when ECT has finished period at old school and started at new school" do
        let!(:old_school_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: 2.months.ago,
                            finished_on: 1.week.ago)
        end

        let!(:new_school_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_b,
                            teacher: transition_teacher,
                            started_on: 1.week.ago,
                            finished_on: nil)
        end

        it "does not show finished old school period" do
          visible_periods = described_class.visible_for_school(school_a)
          expect(visible_periods).not_to include(old_school_period)
        end

        it "shows ongoing new school period" do
          visible_periods = described_class.visible_for_school(school_b)
          expect(visible_periods).to include(new_school_period)
        end
      end

      context "when ECT starts today" do
        let!(:starting_today_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: Date.current,
                            finished_on: nil)
        end

        it "shows period starting today" do
          visible_periods = described_class.visible_for_school(school_a)
          expect(visible_periods).to include(starting_today_period)
        end
      end

      context "when ECT starts tomorrow" do
        let!(:starting_tomorrow_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: Date.current + 1.day,
                            finished_on: nil)
        end

        it "shows period starting tomorrow" do
          visible_periods = described_class.visible_for_school(school_a)
          expect(visible_periods).to include(starting_tomorrow_period)
        end
      end

      context "when ECT finished yesterday" do
        let!(:finished_yesterday_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: 1.month.ago,
                            finished_on: Date.current - 1.day)
        end

        it "does not show period that finished yesterday" do
          visible_periods = described_class.visible_for_school(school_a)
          expect(visible_periods).not_to include(finished_yesterday_period)
        end
      end

      context "dual visibility during school transitions" do
        let(:old_end_date) { 1.week.ago }
        let(:transition_date) { Date.current }
        let(:old_appropriate_body) { FactoryBot.create(:appropriate_body) }
        let(:new_appropriate_body) { FactoryBot.create(:appropriate_body) }

        let!(:finished_old_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_a,
                            teacher: transition_teacher,
                            started_on: 1.month.ago,
                            finished_on: old_end_date,
                            email: 'old@example.com',
                            working_pattern: 'full_time',
                            school_reported_appropriate_body: old_appropriate_body)
        end

        let!(:current_new_period) do
          FactoryBot.create(:ect_at_school_period,
                            school: school_b,
                            teacher: transition_teacher,
                            started_on: transition_date,
                            finished_on: nil,
                            email: 'new@example.com',
                            working_pattern: 'part_time',
                            school_reported_appropriate_body: new_appropriate_body)
        end

        it 'old school no longer sees finished period' do
          old_school_periods = described_class.visible_for_school(school_a)
          expect(old_school_periods).not_to include(finished_old_period)
        end

        it 'new school sees current period' do
          new_school_periods = described_class.visible_for_school(school_b)
          expect(new_school_periods).to include(current_new_period)
          expect(new_school_periods).not_to include(finished_old_period)
        end

        it 'periods maintain their distinct attributes after transition' do
          expect(finished_old_period.email).to eq('old@example.com')
          expect(finished_old_period.working_pattern).to eq('full_time')

          expect(current_new_period.email).to eq('new@example.com')
          expect(current_new_period.working_pattern).to eq('part_time')
        end
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
  end

  describe "#siblings" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: '2022-12-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: period_1.finished_on, finished_on: '2024-01-01') }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: period_2.finished_on, finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: '2022-01-01', finished_on: period_1.started_on) }

    it "returns ect periods only for the specified instance's teacher excluding the instance" do
      expect(ect_at_school_period.siblings).to match_array([period_1, period_2, period_3])
    end
  end
end
