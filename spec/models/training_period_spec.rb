describe TrainingPeriod do
  include SchoolPartnershipHelpers

  describe "declarative updates" do
    let(:period_boundaries) { { started_on: 3.years.ago.to_date, finished_on: nil } }

    context "when target is school" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **period_boundaries) }
      let(:school_partnership) { FactoryBot.create(:school_partnership) }
      let(:instance) { FactoryBot.create(:training_period, ect_at_school_period:, school_partnership:, **period_boundaries) }
      let!(:target) { school_partnership.school }

      it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
    end

    context "when target is teacher" do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:target) { teacher }

      context "ECT training period" do
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, **period_boundaries) }
        let(:instance) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: ect_at_school_period.finished_on) }

        it_behaves_like "a declarative metadata model", on_event: %i[create destroy update], when_changing: %i[started_on finished_on]
      end

      context "Mentor training period" do
        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, **period_boundaries) }
        let(:instance) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: mentor_at_school_period.started_on, finished_on: mentor_at_school_period.finished_on) }

        it_behaves_like "a declarative metadata model", on_event: %i[create destroy update], when_changing: %i[started_on finished_on]
      end
    end
  end

  describe "enums" do
    it "uses the training programme enum" do
      expect(subject).to define_enum_for(:training_programme)
                           .with_values({ provider_led: "provider_led",
                                          school_led: "school_led" })
                           .validating
                           .with_suffix(:training_programme)
                           .backed_by_column_of_type(:enum)
    end

    it "uses the withdrawal_reasons enum" do
      expect(subject).to define_enum_for(:withdrawal_reason)
                           .with_values({
                             left_teaching_profession: "left_teaching_profession",
                             moved_school: "moved_school",
                             mentor_no_longer_being_mentor: "mentor_no_longer_being_mentor",
                             switched_to_school_led: "switched_to_school_led",
                             other: "other"
                           })
                           .validating(allowing_nil: true)
                           .with_suffix(:withdrawal_reason)
                           .backed_by_column_of_type(:enum)
    end

    it "uses the deferral_reasons enum" do
      expect(subject).to define_enum_for(:deferral_reason)
                           .with_values({
                             bereavement: "bereavement",
                             long_term_sickness: "long_term_sickness",
                             parental_leave: "parental_leave",
                             career_break: "career_break",
                             other: "other"
                           })
                           .validating(allowing_nil: true)
                           .with_suffix(:deferral_reason)
                           .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:ect_at_school_period).class_name("ECTAtSchoolPeriod").inverse_of(:training_periods) }
    it { is_expected.to belong_to(:mentor_at_school_period).inverse_of(:training_periods) }
    it { is_expected.to belong_to(:school_partnership) }
    it { is_expected.to have_many(:declarations).inverse_of(:training_period) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_one(:lead_provider_delivery_partnership).through(:school_partnership) }
    it { is_expected.to have_one(:active_lead_provider).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
    it { is_expected.to have_one(:delivery_partner).through(:lead_provider_delivery_partnership) }
    it { is_expected.to have_one(:contract_period).through(:active_lead_provider) }
    it { is_expected.to belong_to(:expression_of_interest).class_name('ActiveLeadProvider') }
    it { is_expected.to have_one(:expression_of_interest_lead_provider).through(:expression_of_interest).source(:lead_provider) }
    it { is_expected.to have_one(:expression_of_interest_contract_period).through(:expression_of_interest).source(:contract_period) }
  end

  describe "validations" do
    it { is_expected.not_to validate_presence_of(:withdrawn_at) }
    it { is_expected.not_to validate_presence_of(:withdrawal_reason) }
    it { is_expected.not_to validate_presence_of(:deferred_at) }
    it { is_expected.not_to validate_presence_of(:deferral_reason) }
    it { is_expected.to validate_presence_of(:started_on) }

    context "when deferred_at and withdrawn_at are both present" do
      subject { FactoryBot.build(:training_period, deferred_at: Time.zone.now, withdrawn_at: Time.zone.now) }

      it "is expected to have an error on base" do
        subject.valid?
        expect(subject.errors.messages[:base]).to include("A training period cannot be both withdrawn and deferred")
      end
    end

    context "when withdrawn_at is present" do
      subject { FactoryBot.build(:training_period, withdrawn_at: Time.zone.now) }

      it { is_expected.to validate_presence_of(:withdrawal_reason) }
    end

    context "when withdrawal_reason is present" do
      subject { FactoryBot.build(:training_period, withdrawal_reason: :moved_school) }

      it { is_expected.to validate_presence_of(:withdrawn_at) }
    end

    context "when deferred_at is present" do
      subject { FactoryBot.build(:training_period, deferred_at: Time.zone.now) }

      it { is_expected.to validate_presence_of(:deferral_reason) }
    end

    context "when deferral_reason is present" do
      subject { FactoryBot.build(:training_period, deferral_reason: :parental_leave) }

      it { is_expected.to validate_presence_of(:deferred_at) }
    end

    context "exactly one id of trainee present" do
      context "when ect_at_school_period_id and mentor_at_school_period_id are all nil" do
        subject do
          FactoryBot.build(:training_period, ect_at_school_period_id: nil, mentor_at_school_period_id: nil)
        end

        it "add an error" do
          subject.valid?
          expect(subject.errors.messages[:base]).to include("Id of trainee missing")
        end
      end

      context "when ect_at_school_period_id and mentor_at_school_period_id are all set" do
        subject do
          FactoryBot.build(:training_period, ect_at_school_period_id: 200, mentor_at_school_period_id: 300)
        end

        it "add an error" do
          subject.valid?
          expect(subject.errors.messages).to include(base: ["Only one id of trainee required. Two given"])
        end
      end
    end

    describe 'presence of expression of interest or school partnership' do
      let(:dates) { { started_on: 3.years.ago.to_date, finished_on: nil } }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **dates) }

      context 'when provider-led' do
        subject { FactoryBot.build(:training_period, :provider_led, ect_at_school_period:, expression_of_interest: nil, school_partnership: nil, **dates) }

        context 'when neither the expression of interest or school partnership is present' do
          it 'has a base error stating either expression of interest or school partnership required' do
            subject.valid?
            expect(subject.errors.messages[:base]).to include('Either expression of interest or school partnership required')
          end
        end

        context 'when just the expression of interest is present' do
          subject { FactoryBot.create(:training_period, :with_expression_of_interest, ect_at_school_period:, **dates) }

          it { is_expected.to(be_valid) }
        end

        context 'when just the school partnership is present' do
          subject { FactoryBot.create(:training_period, :with_school_partnership, ect_at_school_period:, **dates) }

          it { is_expected.to(be_valid) }
        end

        context 'when both the expression of interest and school partnership are present' do
          subject { FactoryBot.create(:training_period, :with_school_partnership, :with_expression_of_interest, ect_at_school_period:, **dates) }

          it { is_expected.to(be_valid) }
        end
      end

      context 'when school-led' do
        subject { FactoryBot.build(:training_period, :school_led, ect_at_school_period:, expression_of_interest: nil, school_partnership: nil, **dates) }

        it 'allows nil expression of interest and training period' do
          expect(subject).to(be_valid)
        end
      end
    end

    describe 'overlapping periods' do
      let(:started_on_message) { 'Start date cannot overlap another Trainee period' }
      let(:finished_on_message) { 'End date cannot overlap another Trainee period' }

      context 'with mentee' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            let(:ect_at_school_period) do
              FactoryBot.create(:ect_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil)
            end
            let(:period) do
              FactoryBot.build(:training_period, ect_at_school_period:,
                                                 started_on: test.new_period_range.first,
                                                 finished_on: test.new_period_range.last)
            end
            let(:messages) { period.errors.messages }

            before do
              FactoryBot.create(:training_period, ect_at_school_period:,
                                                  started_on: test.existing_period_range.first,
                                                  finished_on: test.existing_period_range.last)
              period.valid?
            end

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

      context 'with mentor' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            let(:mentor_at_school_period) do
              FactoryBot.create(:mentor_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil)
            end
            let(:period) do
              FactoryBot.build(:training_period, :for_mentor, mentor_at_school_period:,
                                                              started_on: test.new_period_range.first,
                                                              finished_on: test.new_period_range.last)
            end
            let(:messages) { period.errors.messages }

            before do
              FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:,
                                                               started_on: test.existing_period_range.first,
                                                               finished_on: test.existing_period_range.last)
              period.valid?
            end

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

    describe 'only allows provider-led mentor training' do
      context 'for mentor training' do
        subject { FactoryBot.build(:training_period, :for_mentor) }

        it { is_expected.to allow_value('provider_led').for(:training_programme) }
        it { is_expected.not_to allow_value('school_led').for(:training_programme).with_message('Mentor training periods can only be provider-led') }
      end
    end

    describe 'allows provider-led and school-led ECT training' do
      context 'for ECT training' do
        subject { FactoryBot.build(:training_period, :for_ect) }

        it { is_expected.to allow_value('school_led').for(:training_programme) }
        it { is_expected.to allow_value('provider_led').for(:training_programme) }
      end
    end

    describe 'absence of expression of interest and school partnership for school-led training' do
      let(:dates) { { started_on: 3.years.ago.to_date, finished_on: nil } }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **dates) }

      context 'when school-led' do
        context 'when both expression of interest and school partnership are absent' do
          subject { FactoryBot.build(:training_period, :school_led, ect_at_school_period:, **dates) }

          it { is_expected.to be_valid }
        end

        context 'when expression of interest is present' do
          subject do
            FactoryBot.build(:training_period, :school_led, :with_expression_of_interest,
                             ect_at_school_period:, **dates)
          end

          it 'has an error on expression_of_interest' do
            subject.valid?
            expect(subject.errors.messages[:expression_of_interest]).to include('Expression of interest must be absent for school-led training programmes')
          end
        end

        context 'when school partnership is present' do
          subject do
            FactoryBot.build(:training_period, :school_led, :with_school_partnership,
                             ect_at_school_period:, **dates)
          end

          it 'has an error on school_partnership' do
            subject.valid?
            expect(subject.errors.messages[:school_partnership]).to include('School partnership must be absent for school-led training programmes')
          end
        end

        context 'when both expression of interest and school partnership are present' do
          subject do
            FactoryBot.build(:training_period, :school_led, :with_school_partnership, :with_expression_of_interest,
                             ect_at_school_period:, **dates)
          end

          it 'has errors on both expression_of_interest and school_partnership' do
            subject.valid?
            expect(subject.errors.messages[:expression_of_interest]).to include('Expression of interest must be absent for school-led training programmes')
            expect(subject.errors.messages[:school_partnership]).to include('School partnership must be absent for school-led training programmes')
          end
        end
      end

      context 'when provider-led' do
        context 'when both expression of interest and school partnership are present' do
          subject do
            FactoryBot.build(:training_period, :provider_led, :with_school_partnership, :with_expression_of_interest,
                             ect_at_school_period:, **dates)
          end

          it 'does not validate absence of expression_of_interest and school_partnership' do
            expect(subject).to be_valid
          end
        end
      end
    end
  end

  describe "scopes" do
    describe ".for_ect" do
      it "returns training periods only for the specified ect at school period" do
        expect(TrainingPeriod.for_ect(123).to_sql).to end_with(%(WHERE "training_periods"."ect_at_school_period_id" = 123))
      end
    end

    describe ".for_mentor" do
      it "returns training periods only for the specified mentor at school period" do
        expect(TrainingPeriod.for_mentor(456).to_sql).to end_with(%(WHERE "training_periods"."mentor_at_school_period_id" = 456))
      end
    end

    describe '.at_school' do
      let(:school) { FactoryBot.create(:school) }
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let(:partnership) { make_partnership_for(school, contract_period) }

      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
      let(:ect_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period:,
          school_partnership: partnership,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.finished_on
        )
      end

      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
      let(:mentor_training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period:,
          school_partnership: partnership,
          started_on: mentor_at_school_period.started_on,
          finished_on: mentor_at_school_period.finished_on
        )
      end

      let(:other_school) { FactoryBot.create(:school) }
      let(:other_ect_period) { FactoryBot.create(:ect_at_school_period, school: other_school) }
      let(:other_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: other_ect_period,
          started_on: other_ect_period.started_on,
          finished_on: other_ect_period.finished_on
        )
      end

      it 'returns training periods for ECTs and Mentors at the school' do
        expect(TrainingPeriod.at_school(school.id)).to include(ect_training_period, mentor_training_period)
      end

      it 'does not return training periods for ECTs and Mentors at other schools' do
        expect(TrainingPeriod.at_school(school.id)).not_to include(other_training_period)
      end
    end

    describe ".ect_training_periods_latest_first" do
      let!(:teacher) { FactoryBot.create(:teacher) }

      let!(:school1) { FactoryBot.create(:school) }
      let!(:school_partnership1) { FactoryBot.create(:school_partnership, school: school1) }
      let(:lead_provider1) { school_partnership1.lead_provider }

      let!(:school_partnership2) { FactoryBot.create(:school_partnership, school: school1) }
      let(:lead_provider2) { school_partnership2.lead_provider }

      let!(:ect_at_school_period1) do
        FactoryBot.create(
          :ect_at_school_period,
          school: school1,
          teacher:,
          started_on: 1.year.ago,
          finished_on: 1.year.from_now
        )
      end
      let!(:ect_training_period1) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          started_on: ect_at_school_period1.started_on,
          finished_on: (ect_at_school_period1.started_on + 30.days),
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )
      end
      let!(:ect_training_period2) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          started_on: ect_training_period1.finished_on.next_day,
          finished_on: (ect_training_period1.finished_on + 20.days),
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership1
        )
      end
      let!(:ect_training_period3) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          started_on: ect_training_period2.finished_on.next_day,
          finished_on: ect_at_school_period1.finished_on,
          ect_at_school_period: ect_at_school_period1,
          school_partnership: school_partnership2
        )
      end

      it "returns latest ect training period for lead_provider1" do
        expect(TrainingPeriod.ect_training_periods_latest_first(teacher:, lead_provider: lead_provider1)).to eq([ect_training_period2, ect_training_period1])
      end

      it "returns latest ect training period for lead_provider2" do
        expect(TrainingPeriod.ect_training_periods_latest_first(teacher:, lead_provider: lead_provider2)).to eq([ect_training_period3])
      end
    end

    describe ".mentor_training_periods_latest_first" do
      let!(:teacher) { FactoryBot.create(:teacher) }

      let!(:school1) { FactoryBot.create(:school) }
      let!(:school_partnership1) { FactoryBot.create(:school_partnership, school: school1) }
      let(:lead_provider1) { school_partnership1.lead_provider }

      let!(:school_partnership2) { FactoryBot.create(:school_partnership, school: school1) }
      let(:lead_provider2) { school_partnership2.lead_provider }

      let!(:mentor_at_school_period1) do
        FactoryBot.create(
          :mentor_at_school_period,
          school: school1,
          teacher:,
          started_on: 1.year.ago,
          finished_on: 1.year.from_now
        )
      end
      let!(:mentor_training_period1) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          started_on: mentor_at_school_period1.started_on,
          finished_on: (mentor_at_school_period1.started_on + 30.days),
          mentor_at_school_period: mentor_at_school_period1,
          school_partnership: school_partnership1
        )
      end
      let!(:mentor_training_period2) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          started_on: mentor_training_period1.finished_on.next_day,
          finished_on: (mentor_training_period1.finished_on + 20.days),
          mentor_at_school_period: mentor_at_school_period1,
          school_partnership: school_partnership1
        )
      end
      let!(:mentor_training_period3) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          started_on: mentor_training_period2.finished_on.next_day,
          finished_on: mentor_at_school_period1.finished_on,
          mentor_at_school_period: mentor_at_school_period1,
          school_partnership: school_partnership2
        )
      end

      it "returns latest mentor training period for lead_provider1" do
        expect(TrainingPeriod.mentor_training_periods_latest_first(teacher:, lead_provider: lead_provider1)).to eq([mentor_training_period2, mentor_training_period1])
      end

      it "returns latest mentor training period for lead_provider2" do
        expect(TrainingPeriod.mentor_training_periods_latest_first(teacher:, lead_provider: lead_provider2)).to eq([mentor_training_period3])
      end
    end
  end

  describe "#siblings" do
    subject { training_period_1.siblings }

    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: '2021-01-01') }
    let!(:training_period_1) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: '2022-01-01', finished_on: '2022-06-01') }
    let!(:training_period_2) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: '2022-06-01', finished_on: '2023-01-01') }

    let!(:unrelated_ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: '2021-01-01')
    end

    let!(:unrelated_training_period) do
      FactoryBot.create(:training_period, ect_at_school_period: unrelated_ect_at_school_period, started_on: '2022-06-01', finished_on: '2023-01-01')
    end

    it "only returns records that belong to the same trainee" do
      expect(subject).to include(training_period_2)
    end

    it "doesn't include itself" do
      expect(subject).not_to include(training_period_1)
    end

    it "doesn't include periods that belong to other trainee" do
      expect(subject).not_to include(unrelated_training_period)
    end
  end
end
