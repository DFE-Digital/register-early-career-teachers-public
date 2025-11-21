describe TrainingPeriod do
  include SchoolPartnershipHelpers

  describe "declarative updates" do
    let(:period_boundaries) { { started_on: 3.years.ago.to_date, finished_on: nil } }

    def will_change_attribute(attribute_to_change:, new_value:)
      case attribute_to_change
      when :school_partnership_id
        active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period: instance.schedule.contract_period)
        lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
        school = instance.trainee.school
        FactoryBot.create(:school_partnership, id: new_value, school:, lead_provider_delivery_partnership:)
      when :expression_of_interest_id
        FactoryBot.create(:active_lead_provider, contract_period: instance.schedule.contract_period, id: new_value)
      end
    end

    context "when target is school" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school: target || FactoryBot.create(:school), **period_boundaries) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, school: ect_at_school_period.school) }
      let(:instance) { FactoryBot.create(:training_period, ect_at_school_period:, school_partnership:, **period_boundaries) }
      let!(:target) { FactoryBot.create(:school) }

      it_behaves_like "a declarative metadata model", on_event: %i[create destroy update], when_changing: %i[school_partnership_id expression_of_interest_id]
    end

    context "when target is teacher" do
      let(:teacher) { FactoryBot.create(:teacher) }
      let!(:target) { teacher }

      context "ECT training period" do
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, **period_boundaries) }
        let(:instance) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: ect_at_school_period.finished_on) }

        it_behaves_like "a declarative metadata model", on_event: %i[create destroy update], when_changing: %i[started_on finished_on school_partnership_id]
      end

      context "Mentor training period" do
        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, **period_boundaries) }
        let(:instance) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: mentor_at_school_period.started_on, finished_on: mentor_at_school_period.finished_on) }

        it_behaves_like "a declarative metadata model", on_event: %i[create destroy update], when_changing: %i[started_on finished_on school_partnership_id]
      end
    end
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:training_period, :for_ect, :ongoing) }

    context "target teacher" do
      let(:target) { instance.trainee.teacher }

      def will_change_attribute(attribute_to_change:, new_value:)
        case attribute_to_change
        when :school_partnership_id
          active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period: instance.schedule.contract_period)
          lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
          school = instance.trainee.school
          FactoryBot.create(:school_partnership, id: new_value, lead_provider_delivery_partnership:, school:)
        when :schedule_id
          FactoryBot.create(:schedule, id: new_value)
        when :ect_at_school_period_id
          FactoryBot.create(:ect_at_school_period, id: new_value, teacher: instance.trainee.teacher)
        when :mentor_at_school_period_id
          FactoryBot.create(:mentor_at_school_period, id: new_value, teacher: instance.trainee.teacher)
        end
      end

      it_behaves_like "a declarative touch model", when_changing: %i[ withdrawn_at
                                                                      withdrawal_reason
                                                                      deferred_at
                                                                      deferral_reason
                                                                      started_on
                                                                      finished_on
                                                                      ect_at_school_period_id
                                                                      mentor_at_school_period_id
                                                                      schedule_id
                                                                      school_partnership_id], timestamp_attribute: :api_updated_at
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
    it { is_expected.to belong_to(:expression_of_interest).class_name("ActiveLeadProvider") }
    it { is_expected.to have_one(:expression_of_interest_lead_provider).through(:expression_of_interest).source(:lead_provider) }
    it { is_expected.to have_one(:expression_of_interest_contract_period).through(:expression_of_interest).source(:contract_period) }
    it { is_expected.to belong_to(:schedule) }
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

    describe "presence of expression of interest or school partnership" do
      let(:dates) { { started_on: 3.years.ago.to_date, finished_on: nil } }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **dates) }
      let(:school) { ect_at_school_period.school }
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:school_partnership) { make_partnership_for(school, contract_period) }
      let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, contract_period:) }

      context "when provider-led" do
        subject { FactoryBot.build(:training_period, :provider_led, :with_no_school_partnership, ect_at_school_period:, expression_of_interest: nil, **dates) }

        context "when neither the expression of interest or school partnership is present" do
          it "has a base error stating either expression of interest or school partnership required" do
            subject.valid?
            expect(subject.errors.messages[:base]).to include("Either expression of interest or school partnership required")
          end
        end

        context "when just the expression of interest is present" do
          subject { FactoryBot.create(:training_period, :with_only_expression_of_interest, ect_at_school_period:, **dates) }

          it { is_expected.to(be_valid) }
        end

        context "when just the school partnership is present" do
          subject { FactoryBot.create(:training_period, school_partnership:, ect_at_school_period:, **dates) }

          it { is_expected.to(be_valid) }
        end

        context "when both the expression of interest and school partnership are present" do
          subject { FactoryBot.create(:training_period, expression_of_interest:, school_partnership:, ect_at_school_period:, **dates) }

          it { is_expected.to(be_valid) }
        end
      end

      context "when school-led" do
        subject { FactoryBot.build(:training_period, :school_led, :with_no_school_partnership, expression_of_interest: nil, ect_at_school_period:, **dates) }

        it "allows nil expression of interest and training period" do
          expect(subject).to(be_valid)
        end
      end
    end

    describe "overlapping periods" do
      let(:started_on_message) { "Start date cannot overlap another Trainee period" }
      let(:finished_on_message) { "End date cannot overlap another Trainee period" }

      context "with mentee" do
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

      context "with mentor" do
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

    describe "only allows provider-led mentor training" do
      context "for mentor training" do
        subject { FactoryBot.build(:training_period, :for_mentor) }

        it { is_expected.to allow_value("provider_led").for(:training_programme) }
        it { is_expected.not_to allow_value("school_led").for(:training_programme).with_message("Mentor training periods can only be provider-led") }
      end
    end

    describe "allows provider-led and school-led ECT training" do
      context "for ECT training" do
        subject { FactoryBot.build(:training_period, :for_ect) }

        it { is_expected.to allow_value("school_led").for(:training_programme) }
        it { is_expected.to allow_value("provider_led").for(:training_programme) }
      end
    end

    describe "absence of expression of interest and school partnership for school-led training" do
      let(:dates) { { started_on: 3.years.ago.to_date, finished_on: nil } }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, **dates) }
      let(:school) { ect_at_school_period.school }
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:school_partnership) { make_partnership_for(school, contract_period) }
      let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, contract_period:) }

      context "when school-led" do
        context "when both expression of interest and school partnership are absent" do
          subject { FactoryBot.build(:training_period, :school_led, ect_at_school_period:, **dates) }

          it { is_expected.to be_valid }
        end

        context "when expression of interest is present" do
          subject do
            FactoryBot.build(:training_period, :school_led, expression_of_interest:,
                                                            ect_at_school_period:, **dates)
          end

          it "has an error on expression_of_interest" do
            subject.valid?
            expect(subject.errors.messages[:expression_of_interest]).to include("Expression of interest must be absent for school-led training programmes")
          end
        end

        context "when school partnership is present" do
          subject do
            FactoryBot.build(:training_period, :school_led, school_partnership:,
                                                            ect_at_school_period:, **dates)
          end

          it "has an error on school_partnership" do
            subject.valid?
            expect(subject.errors.messages[:school_partnership]).to include("School partnership must be absent for school-led training programmes")
          end
        end

        context "when both expression of interest and school partnership are present" do
          subject do
            FactoryBot.build(:training_period, :school_led, school_partnership:, expression_of_interest:,
                                                            ect_at_school_period:, **dates)
          end

          it "has errors on both expression_of_interest and school_partnership" do
            subject.valid?
            expect(subject.errors.messages[:expression_of_interest]).to include("Expression of interest must be absent for school-led training programmes")
            expect(subject.errors.messages[:school_partnership]).to include("School partnership must be absent for school-led training programmes")
          end
        end
      end

      context "when provider-led" do
        context "when both expression of interest and school partnership are present" do
          subject do
            FactoryBot.build(:training_period, :provider_led, school_partnership:, expression_of_interest:,
                                                              ect_at_school_period:, **dates)
          end

          it "does not validate absence of expression_of_interest and school_partnership" do
            expect(subject).to be_valid
          end
        end
      end
    end

    describe "check if schedule contract period matches" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil) }
      let(:school) { ect_at_school_period.school }
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
      let(:school_partnership) { make_partnership_for(school, contract_period) }
      let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, contract_period:) }

      context "contract period from school partnership" do
        context "when contract periods match" do
          subject { FactoryBot.build(:training_period, :ongoing, schedule:, school_partnership:, ect_at_school_period:) }

          it { is_expected.to be_valid }
        end

        context "when contract periods do not match" do
          subject { FactoryBot.build(:training_period, :ongoing, schedule:, school_partnership: mismatched_school_partnership, ect_at_school_period:) }

          let(:mismatched_school_partnership) { make_partnership_for(school, FactoryBot.create(:contract_period, year: 2025)) }

          it "adds an error to schedule" do
            subject.valid?

            expect(subject.errors[:schedule]).to include("Contract period of schedule must match contract period of EOI and/or school partnership")
          end
        end
      end

      context "contract period from expression of interest" do
        context "when contract periods match" do
          subject do
            FactoryBot.build(
              :training_period,
              :for_ect,
              :ongoing,
              :provider_led,
              :with_no_school_partnership,
              expression_of_interest:,
              ect_at_school_period:,
              schedule:,
              started_on: ect_at_school_period.started_on
            )
          end

          it { is_expected.to be_valid }
        end

        context "when contract periods do not match" do
          subject do
            FactoryBot.build(
              :training_period,
              :for_ect,
              :ongoing,
              :provider_led,
              :with_no_school_partnership,
              expression_of_interest: mismatched_expression_of_interest,
              ect_at_school_period:,
              schedule:,
              started_on: ect_at_school_period.started_on
            )
          end

          let(:mismatched_expression_of_interest) { FactoryBot.create(:active_lead_provider, contract_period: FactoryBot.create(:contract_period, year: 2025)) }

          it "adds an error to schedule" do
            subject.valid?

            expect(subject.errors[:schedule]).to include("Contract period of schedule must match contract period of EOI and/or school partnership")
          end
        end

        context "when training period is `school-led`" do
          subject { FactoryBot.build(:training_period, :ongoing, :school_led, schedule:, ect_at_school_period:) }

          it "adds an error to schedule" do
            subject.valid?

            expect(subject.errors[:schedule]).to include("Schedule must be absent for school-led training programmes")
          end
        end
      end
    end

    describe "schedule presence for provider-led training" do
      it "requires schedule for provider-led training periods" do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil)
        school_partnership = FactoryBot.create(:school_partnership, school: ect_at_school_period.school)
        training_period = FactoryBot.build(:training_period, :for_ect, :provider_led, ect_at_school_period:, school_partnership:, schedule: nil)
        training_period.valid?
        expect(training_period.errors[:schedule]).to include("Schedule is required for provider-led training periods")
      end

      it "does not require schedule for school-led training periods" do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil)
        training_period = FactoryBot.build(:training_period, :for_ect, :school_led, ect_at_school_period:, schedule: nil)
        training_period.valid?
        expect(training_period.errors[:schedule]).not_to include("Schedule is required for provider-led training periods")
      end

      it "is valid when provider-led training period has a schedule" do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil)
        school_partnership = FactoryBot.create(:school_partnership, school: ect_at_school_period.school)
        schedule = FactoryBot.create(:schedule, contract_period: school_partnership.contract_period)
        training_period = FactoryBot.build(:training_period, :for_ect, :provider_led, ect_at_school_period:, school_partnership:, schedule:)
        training_period.valid?
        expect(training_period.errors[:schedule]).to be_empty
      end
    end

    describe "schedule applicable for trainee" do
      it "adds an error when an ECT is assigned to a replacement schedule" do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil)
        training_period = FactoryBot.build(:training_period, :for_ect, ect_at_school_period:, schedule: FactoryBot.create(:schedule, :replacement_schedule))
        training_period.valid?
        expect(training_period.errors[:schedule]).to include("Only mentors can be assigned to replacement schedules")
      end

      it "does not add an error when a mentor is assigned to a replacement schedule" do
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil)
        training_period = FactoryBot.build(:training_period, :for_mentor, mentor_at_school_period:, schedule: FactoryBot.create(:schedule, :replacement_schedule))
        training_period.valid?
        expect(training_period.errors[:schedule]).to be_empty
      end

      it "does not add an error when an ECT is assigned to a non-replacement schedule" do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: Date.new(2024, 12, 25), finished_on: nil)
        training_period = FactoryBot.build(:training_period, :for_ect, ect_at_school_period:, schedule: FactoryBot.create(:schedule))
        training_period.valid?
        expect(training_period.errors[:schedule]).to be_empty
      end
    end

    describe "school consistency" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
      let(:training_period) { FactoryBot.build(:training_period, ect_at_school_period:, school_partnership:, expression_of_interest:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school: ect_at_school_period.school) }
      let!(:expression_of_interest) { nil }

      context "when the school partnership's school matches the trainee's school" do
        it { expect(training_period).to be_valid }
      end

      context "when the school partnership is not set" do
        let!(:school_partnership) { nil }
        let!(:expression_of_interest) { FactoryBot.create(:active_lead_provider) }

        it { expect(training_period).to be_valid }
      end

      context "when the school partnership's school does not match the trainee's school" do
        let(:school_partnership) { FactoryBot.create(:school_partnership) }

        it "adds an error to school_partnership" do
          training_period.valid?
          expect(training_period.errors[:school_partnership]).to include("School partnership's school must match the trainee's school")
        end

        it "sends a message to Sentry" do
          expect(Sentry).to receive(:capture_message).with(
            "[Data integrity] Attempt to assign school partnership to a different school from the school period",
            level: :error,
            extra: {
              teacher_id: training_period.trainee.teacher.id,
              school_partnership_id: school_partnership.id,
              trainee_school_id: training_period.trainee.school_id
            }
          )
          training_period.valid?
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

    describe ".at_school" do
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

      it "returns training periods for ECTs and Mentors at the school" do
        expect(TrainingPeriod.at_school(school.id)).to include(ect_training_period, mentor_training_period)
      end

      it "does not return training periods for ECTs and Mentors at other schools" do
        expect(TrainingPeriod.at_school(school.id)).not_to include(other_training_period)
      end
    end
  end

  describe "#siblings" do
    subject { training_period_1.siblings }

    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: "2021-01-01") }
    let!(:training_period_1) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: "2022-01-01", finished_on: "2022-06-01") }
    let!(:training_period_2) { FactoryBot.create(:training_period, ect_at_school_period:, started_on: "2022-06-01", finished_on: "2023-01-01") }

    let!(:unrelated_ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: "2021-01-01")
    end

    let!(:unrelated_training_period) do
      FactoryBot.create(:training_period, ect_at_school_period: unrelated_ect_at_school_period, started_on: "2022-06-01", finished_on: "2023-01-01")
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
