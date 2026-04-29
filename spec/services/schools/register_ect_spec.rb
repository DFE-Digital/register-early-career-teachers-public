RSpec.describe Schools::RegisterECT do
  include ActiveJob::TestHelper
  subject(:service) do
    described_class.new(school_reported_appropriate_body:,
                        corrected_name:,
                        email:,
                        lead_provider:,
                        training_programme:,
                        school:,
                        started_on:,
                        trn:,
                        trs_first_name:,
                        trs_last_name:,
                        working_pattern:,
                        author:,
                        store:)
  end

  let(:store) { nil }
  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:school_reported_appropriate_body) { FactoryBot.create(:appropriate_body_period) }
  let(:corrected_name) { "Randy Marsh" }
  let(:email) { "randy@tegridyfarms.com" }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { mid_year }
  let(:trn) { "3002586" }
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:working_pattern) { "full_time" }
  let(:ect_at_school_period) { subject.teacher.ect_at_school_periods.first }
  let!(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }

  include_context "safe_schedules"

  describe "#register!" do
    context "when a Teacher record with the same TRN does not exist" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:training_programme) { "provider_led" }

      before { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

      it "creates a new Teacher record" do
        expect { service.register! }.to change(Teacher, :count).by(1)

        created_teacher = Teacher.find_by(trn:)
        expect(created_teacher.trs_first_name).to eq(trs_first_name)
        expect(created_teacher.trs_last_name).to eq(trs_last_name)
        expect(created_teacher.corrected_name).to eq(corrected_name)
        expect(created_teacher.api_ect_training_record_id).to be_present
      end

      context "when we log a teacher to start on the last day of the current contract period" do
        let(:started_on) { contract_period.finished_on }

        it "creates a new Teacher record" do
          expect { service.register! }.to change(Teacher, :count).by(1)
        end
      end
    end

    context "when provider led" do
      let(:training_programme) { "provider_led" }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }

      context "when no ActiveLeadProvider exists for the contract_period" do
        it "raises an error" do
          expect { service.register! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when an ActiveLeadProvider exists for the contract_period" do
        let!(:active_lead_provider) do
          FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
        end
        let!(:teacher) { FactoryBot.create(:teacher, trn:) }

        it "creates an associated ECTAtSchoolPeriod record" do
          expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

          expect(ect_at_school_period).to have_attributes(
            teacher_id: Teacher.find_by(trn:).id,
            started_on:,
            working_pattern:,
            email:,
            school_reported_appropriate_body_id: school_reported_appropriate_body.id
          )
        end

        it "sends a provider-led confirmation email to the early career teacher" do
          expect { service.register! }
            .to have_enqueued_mail(Schools::ECTRegistrationMailer, :provider_led_confirmation)
        end

        it "records a teacher_registered_as_ect event" do
          allow(Events::Record)
            .to receive(:record_teacher_registered_as_ect_event!)
            .with(any_args)
            .and_call_original

          service.register!

          expect(Events::Record)
            .to have_received(:record_teacher_registered_as_ect_event!)
            .with(
              hash_including(author:, ect_at_school_period:, teacher:, school:)
            )
        end

        it "sets appropriate body and provider choices for the school" do
          expect { service.register! }
            .to change(school, :last_chosen_appropriate_body_id)
              .to(school_reported_appropriate_body.id)
            .and change(school, :last_chosen_training_programme)
              .to(training_programme)
            .and change(school, :last_chosen_lead_provider_id)
              .to(lead_provider.id)
        end

        it "calls `Teachers::SetECTFundingEligibility` service with correct params" do
          allow(Teachers::SetECTFundingEligibility).to receive(:new).and_call_original

          service.register!

          expect(Teachers::SetECTFundingEligibility).to have_received(:new).with(teacher:, author:)
        end

        context "when a Teacher has no ECT periods" do
          it "doesn't create a new Teacher record" do
            expect { service.register! }.not_to change(Teacher, :count)
          end
        end

        context "when a Teacher has an ECT period at a different school" do
          let(:other_school) { FactoryBot.create(:school) }

          before do
            FactoryBot.create(
              :ect_at_school_period,
              :ongoing,
              teacher:,
              school: other_school,
              started_on: Date.new(2024, 1, 1)
            )
          end

          it "allows registration (school transfer)" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)
          end
        end

        context "when a Teacher has an ongoing ECT period at the current school" do
          before do
            FactoryBot.create(
              :ect_at_school_period,
              :ongoing,
              teacher:,
              school:,
              started_on: Date.new(2024, 1, 1)
            )
          end

          it "raises an exception" do
            expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)
          end

          it "does not enqueue a confirmation email" do
            ActiveJob::Base.queue_adapter.enqueued_jobs.clear

            expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)

            expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
          end
        end

        context "when a Teacher has multiple ECT periods at different schools" do
          let(:school_one) { FactoryBot.create(:school) }
          let(:school_two) { FactoryBot.create(:school) }
          let(:started_on) { 1.day.from_now }

          before do
            # Create finished periods at two different schools with non-overlapping dates
            FactoryBot.create(:ect_at_school_period, :finished, teacher:, school: school_one, started_on: 2.years.ago, finished_on: 18.months.ago)
            FactoryBot.create(:ect_at_school_period, :finished, teacher:, school: school_two, started_on: 12.months.ago, finished_on: 6.months.ago)
          end

          it "allows registration at a third school (multiple transfers)" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

            expect(teacher.ect_at_school_periods.count).to eq(3)
          end

          context "on the last day of the current contract period" do
            let(:overridden_current_date) { contract_period.finished_on }
            let(:started_on) { overridden_current_date }

            it "allows registration at a third school (multiple transfers)" do
              expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)
            end
          end
        end

        context "when a Teacher has an ongoing ECT period at a different school and a finished ECT period at the current school" do
          let(:other_school) { FactoryBot.create(:school) }

          before do
            # Finished at current school (previous period)
            FactoryBot.create(:ect_at_school_period, :finished, teacher:, school:, started_on: Date.new(2023, 9, 1), finished_on: Date.new(2023, 12, 31))
            # Ongoing at other school (started after the finished period)
            FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school: other_school, started_on: Date.new(2024, 1, 1))
          end

          it "closes the ongoing period and allows registration at the current school" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

            # The ongoing period at the other school should be closed
            ongoing_period = teacher.ect_at_school_periods.find_by(school: other_school)
            expect(ongoing_period.finished_on).to eq(started_on - 1.day)

            # New period at current school should be created
            new_period = teacher.ect_at_school_periods.find_by(school:, finished_on: nil)
            expect(new_period.started_on).to eq(started_on)
          end

          context "on the last day of the current contract period" do
            let(:started_on) { contract_period.finished_on }

            it "allows registration at the current school" do
              expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)
            end
          end
        end

        context "when a Teacher has an ECT period finishing in future at a different school (reported leaving)" do
          let(:other_school) { FactoryBot.create(:school) }
          let(:started_on) { Date.new(2025, 8, 1) + 1.year }

          before do
            FactoryBot.create(
              :ect_at_school_period,
              teacher:,
              school: other_school,
              started_on: 6.months.ago,
              finished_on: 6.months.from_now
            )
          end

          it "allows registration with non-overlapping future date" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)
          end
        end

        context "when a Teacher already has an ongoing ECT period starting in future at a different school (reported joining)" do
          let(:other_school) { FactoryBot.create(:school) }
          let(:started_on) { Date.new(2025, 8, 1) + 1.year }

          before do
            FactoryBot.create(
              :ect_at_school_period,
              :ongoing,
              teacher:,
              school: other_school,
              started_on: started_on.advance(weeks: 2)
            )
          end

          it "raises an error" do
            expect { service.register! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Finished on End date cannot overlap another Teacher ECT period"
            )
          end
        end

        context "when no SchoolPartnerships exist" do
          it "creates a TrainingPeriod linked to the ECTAtSchoolPeriod and with an expression of interest for the ActiveLeadProvider" do
            expect { service.register! }.to change(TrainingPeriod, :count).by(1)

            training_period = TrainingPeriod.find_by!(started_on:)

            expect(training_period.ect_at_school_period.teacher).to eq(teacher)
            expect(training_period.ect_at_school_period).to eq(ect_at_school_period)
            expect(training_period.started_on).to eq(started_on)
            expect(training_period.expression_of_interest).to eq(active_lead_provider)
            expect(training_period.school_partnership).to be_nil
            expect(training_period.training_programme).to eq(training_programme)
          end

          context "on the last day of the contract period" do
            let(:overridden_current_date) { contract_period.finished_on }
            let(:started_on) { overridden_current_date }

            it "finds the correct contract period and schedule" do
              expect { service.register! }.to change(TrainingPeriod, :count).by(1)

              training_period = TrainingPeriod.find_by!(started_on:)

              expect(training_period.started_on).to eq(started_on)
              expect(training_period.schedule.identifier).to eql("ecf-standard-april")
              expect(training_period.schedule.contract_period_year).to be(2025)
            end
          end
        end

        context "when a SchoolPartnership exists" do
          let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
          let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

          it "creates a TrainingPeriod with a school_partnership and no expression_of_interest" do
            expect { service.register! }.to change(TrainingPeriod, :count).by(1)

            training_period = TrainingPeriod.find_by!(started_on:)

            expect(training_period.expression_of_interest).to be_nil
            expect(training_period.school_partnership).to eq(school_partnership)
          end

          context "on the last day of the contract period" do
            let(:overridden_current_date) { contract_period.finished_on }
            let(:started_on) { overridden_current_date }

            it "finds the correct contract period and schedule" do
              expect { service.register! }.to change(TrainingPeriod, :count).by(1)

              training_period = TrainingPeriod.find_by!(started_on:)

              expect(training_period.started_on).to eq(started_on)
              expect(training_period.schedule.identifier).to eql("ecf-standard-april")
              expect(training_period.schedule.contract_period_year).to be(2025)
            end
          end
        end

        context "when the ECT start date is backdated before the registration contract period" do
          let(:started_on) { contract_period.started_on - 1.day }

          it "keeps the ECTAtSchoolPeriod started_on backdated, but uses the registration date for the TrainingPeriod started_on" do
            expect { service.register! }.to change(TrainingPeriod, :count).by(1)

            training_period = ect_at_school_period.training_periods.order(:created_at).last

            expect(ect_at_school_period.started_on).to eq(started_on)
            expect(training_period.started_on).to eq(Date.current)
            expect(training_period.schedule.contract_period_year).to eq(contract_period.year)
            expect(training_period.started_on).not_to eq(ect_at_school_period.started_on)
          end
        end
      end

      context "when contract period reassignment is required" do
        let(:started_on) { Date.new(2024, 1, 1) }
        let!(:frozen_cp) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }
        let!(:successor_cp) { FactoryBot.create(:contract_period, :with_schedules, :with_extended_schedule, year: 2024) }
        let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: successor_cp) }
        let!(:teacher) { FactoryBot.create(:teacher, trn:) }

        let(:previous_school) { FactoryBot.create(:school) }
        let!(:previous_ect_period) do
          FactoryBot.create(:ect_at_school_period,
                            teacher:,
                            school: previous_school,
                            started_on: Date.new(2022, 9, 1),
                            finished_on: Date.new(2023, 8, 31))
        end

        let!(:previous_training_period) do
          FactoryBot.create(:training_period,
                            ect_at_school_period: previous_ect_period,
                            mentor_at_school_period: nil,
                            training_programme: "provider_led",
                            school_partnership: FactoryBot.create(:school_partnership, :for_year, year: 2022, school: previous_school),
                            schedule: FactoryBot.create(:schedule, contract_period: frozen_cp, identifier: "ecf-standard-september"),
                            started_on: Date.new(2022, 9, 1),
                            finished_on: Date.new(2023, 8, 31))
        end

        let(:store) { double("store", previous_training_period:, school_partnership_to_reuse_id: nil) }

        it "uses the reassigned contract period start date, not the registration date" do
          service.register!

          new_ect_period = service.ect_at_school_period
          training_period = new_ect_period.training_periods.order(:created_at).last

          expect(training_period.started_on).to eq(successor_cp.started_on)
          expect(training_period.started_on).not_to eq(Date.current)
        end
      end

      context "when the ECT is continuing provider-led training from a previous school" do
        let!(:teacher) { FactoryBot.create(:teacher, trn:) }
        let(:previous_school) { FactoryBot.create(:school) }
        let(:previous_contract_period) { FactoryBot.create(:contract_period, :with_schedules, year: 2024) }
        let(:started_on) { Date.new(2025, 9, 1) }

        let(:previous_active_lead_provider) do
          FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period)
        end

        let(:previous_lead_provider_delivery_partnership) do
          FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: previous_active_lead_provider)
        end

        let(:previous_school_partnership) do
          FactoryBot.create(
            :school_partnership,
            school: previous_school,
            lead_provider_delivery_partnership: previous_lead_provider_delivery_partnership
          )
        end

        let(:previous_ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher:,
            school: previous_school,
            started_on: Date.new(2024, 9, 1),
            finished_on: Date.new(2025, 8, 31)
          )
        end

        let(:previous_schedule) do
          FactoryBot.create(
            :schedule,
            contract_period: previous_contract_period,
            identifier: "ecf-standard-september"
          )
        end

        let!(:previous_training_period) do
          FactoryBot.create(
            :training_period,
            ect_at_school_period: previous_ect_period,
            training_programme: "provider_led",
            school_partnership: previous_school_partnership,
            schedule: previous_schedule,
            started_on: Date.new(2024, 9, 1),
            finished_on: Date.new(2025, 8, 31)
          )
        end

        let(:store) do
          double(
            "store",
            previous_training_period:,
            school_partnership_to_reuse_id: nil
          )
        end

        it "keeps the previous contract period for the new EOI training period" do
          service.register!

          new_training_period = service.ect_at_school_period.training_periods.order(:created_at).last

          expect(new_training_period.expression_of_interest.contract_period)
            .to eq(previous_contract_period)

          expect(new_training_period.school_partnership).to be_nil

          expect(new_training_period.schedule.contract_period)
            .to eq(previous_contract_period)

          expect(new_training_period.schedule.identifier)
            .to eq(previous_training_period.schedule.identifier)

          expect(new_training_period.schedule.contract_period)
  .not_to eq(contract_period)
        end

        context "when the new school has a matching partnership in the previous contract period" do
          let!(:new_school_partnership) do
            FactoryBot.create(
              :school_partnership,
              school:,
              lead_provider_delivery_partnership: FactoryBot.create(
                :lead_provider_delivery_partnership,
                active_lead_provider: previous_active_lead_provider
              )
            )
          end

          it "keeps the previous contract period and uses the matching school partnership" do
            service.register!

            new_training_period = service.ect_at_school_period.training_periods.order(:created_at).last

            expect(new_training_period.school_partnership).to eq(new_school_partnership)
            expect(new_training_period.expression_of_interest).to be_nil

            expect(new_training_period.school_partnership.active_lead_provider.contract_period)
              .to eq(previous_contract_period)

            expect(new_training_period.schedule.contract_period)
              .to eq(previous_contract_period)

            expect(new_training_period.schedule.identifier)
              .to eq(previous_training_period.schedule.identifier)
          end
        end

        context "when the new school has a partnership but in a different contract period" do
          let!(:different_active_lead_provider) do
            FactoryBot.create(
              :active_lead_provider,
              lead_provider:,
              contract_period:
            )
          end

          let!(:new_school_partnership) do
            FactoryBot.create(
              :school_partnership,
              school:,
              lead_provider_delivery_partnership: FactoryBot.create(
                :lead_provider_delivery_partnership,
                active_lead_provider: different_active_lead_provider
              )
            )
          end

          it "falls back to EOI in the previous contract period" do
            service.register!

            new_training_period = service.ect_at_school_period.training_periods.last

            expect(new_training_period.school_partnership).to be_nil
            expect(new_training_period.expression_of_interest.contract_period)
              .to eq(previous_contract_period)
          end
        end
      end
    end

    context "when school-led" do
      let(:training_programme) { "school_led" }
      let(:lead_provider) { nil }

      before { FactoryBot.create(:teacher, trn:) }

      it "creates a TrainingPeriod" do
        expect { service.register! }.to change(TrainingPeriod, :count).by(1)
      end

      it "sends a school-led confirmation email to the early career teacher" do
        expect { service.register! }
          .to have_enqueued_mail(Schools::ECTRegistrationMailer, :school_led_confirmation)
      end

      it "has no expression of interest or school partnership" do
        service.register!

        training_period = TrainingPeriod.find_by!(started_on:)

        expect(training_period.school_partnership).to be_nil
        expect(training_period.expression_of_interest).to be_nil
      end

      it "has training programme: school_led" do
        service.register!

        training_period = TrainingPeriod.find_by!(started_on:)

        expect(training_period.training_programme).to eql("school_led")
      end
    end

    context "when switching from provider-led to school-led" do
      let(:training_programme) { "school_led" }
      let(:lead_provider) { nil }

      before do
        school.update!(
          last_chosen_lead_provider: FactoryBot.create(:lead_provider),
          last_chosen_training_programme: "provider_led",
          last_chosen_appropriate_body: nil
        )
      end

      it "updates the last chosen fields correctly" do
        expect { service.register! }
          .to change { school.reload.last_chosen_lead_provider_id }.to(nil)
           .and change { school.reload.last_chosen_training_programme }.to("school_led")
           .and change { school.reload.last_chosen_appropriate_body }.to(school_reported_appropriate_body)
      end
    end

    context "when ECT is transferring from another school" do
      let(:training_programme) { "school_led" }
      let(:lead_provider) { nil }
      let(:other_school) { FactoryBot.create(:school) }
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }
      let(:expected_finished_on) { started_on.yesterday }

      let!(:existing_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: other_school,
          started_on: Date.new(2024, 1, 1),
          finished_on: nil
        )
      end

      it "closes the ongoing ECT period at the previous school" do
        expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
          ect_at_school_period: existing_period,
          finished_on: expected_finished_on,
          author:
        ).and_call_original

        service.register!

        existing_period.reload
        expect(existing_period.finished_on).to eq(expected_finished_on)
      end

      it "allows registration at the new school" do
        expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

        new_period = teacher.ect_at_school_periods.find_by(school:)
        expect(new_period.started_on).to eq(started_on)
      end

      it "records a teacher_left_school_as_ect event for the previous school period" do
        allow(Events::Record).to receive(:record_teacher_left_school_as_ect!).and_call_original

        service.register!

        expect(Events::Record).to have_received(:record_teacher_left_school_as_ect!).with(
          hash_including(
            author:,
            ect_at_school_period: existing_period,
            school: other_school,
            teacher:,
            happened_at: expected_finished_on
          )
        )
      end

      context "when transfer happens today" do
        let(:started_on) { Date.current }

        it "closes ongoing periods that started on or before today" do
          expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
            ect_at_school_period: existing_period,
            finished_on: expected_finished_on,
            author:
          ).and_call_original

          service.register!

          existing_period.reload
          expect(existing_period.finished_on).to eq(expected_finished_on)
        end
      end

      context "when period 1 started before today and period 2 starts today" do
        let!(:existing_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher:,
            school: other_school,
            started_on: 3.days.ago,
            finished_on: nil
          )
        end
        let(:started_on) { Date.current }

        it "closes the existing period that started before today when new period starts today" do
          expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
            ect_at_school_period: existing_period,
            finished_on: expected_finished_on,
            author:
          ).and_call_original

          service.register!

          existing_period.reload
          expect(existing_period.finished_on).to eq(expected_finished_on)

          new_period = teacher.ect_at_school_periods.find_by(school:)
          expect(new_period.started_on).to eq(started_on)
          expect(new_period.finished_on).to be_nil
        end
      end
    end

    context "when ECT is transferring from another school and the previous period has a future leaving date" do
      let(:training_programme) { "school_led" }
      let(:lead_provider) { nil }
      let(:other_school) { FactoryBot.create(:school) }
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }
      let(:started_on) { Date.new(2026, 3, 15) }
      let(:expected_finished_on) { started_on.yesterday }

      let!(:existing_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: other_school,
          started_on: Date.new(2025, 8, 1),
          finished_on: Date.new(2026, 3, 18),
          reported_leaving_by_school_id: other_school.id
        )
      end

      it "finishes the previous ECT period using ECTAtSchoolPeriods::Finish" do
        expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
          ect_at_school_period: existing_period,
          finished_on: expected_finished_on,
          author:
        ).and_call_original

        service.register!
      end

      it "updates the previous ECT period to end the day before the new start date" do
        service.register!

        expect(existing_period.reload.finished_on).to eq(expected_finished_on)
      end

      it "creates a new ECT period at the new school" do
        expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

        new_period = teacher.ect_at_school_periods.find_by!(school:)
        expect(new_period.started_on).to eq(started_on)
        expect(new_period.finished_on).to be_nil
      end

      it "records a leaving event for the previous school period" do
        allow(Events::Record).to receive(:record_teacher_left_school_as_ect!).and_call_original

        service.register!

        expect(Events::Record).to have_received(:record_teacher_left_school_as_ect!).with(
          hash_including(
            author:,
            ect_at_school_period: existing_period,
            school: other_school,
            teacher:,
            happened_at: expected_finished_on
          )
        )
      end

      it "persists the leaving and registration events" do
        perform_enqueued_jobs do
          service.register!
        end

        event_types = Event.where(teacher:).pluck(:event_type)

        expect(event_types).to include("teacher_left_school_as_ect", "teacher_registered_as_ect")
      end
    end

    context "when ECT is transferring from another school on the same date as the previously reported leaving date" do
      let(:training_programme) { "school_led" }
      let(:lead_provider) { nil }
      let(:other_school) { FactoryBot.create(:school) }
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }
      let(:started_on) { Date.new(2026, 3, 18) }
      let(:expected_finished_on) { started_on.yesterday }

      let!(:existing_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: other_school,
          started_on: Date.new(2025, 8, 1),
          finished_on: started_on,
          reported_leaving_by_school_id: other_school.id
        )
      end

      it "updates the previous period to end the day before the new start date" do
        service.register!

        expect(existing_period.reload.finished_on).to eq(expected_finished_on)

        new_period = teacher.ect_at_school_periods.find_by!(school:)
        expect(new_period.started_on).to eq(started_on)
      end
    end

    context "when ECT is transferring from another school and the previous period does not overlap the new start date" do
      let(:training_programme) { "school_led" }
      let(:lead_provider) { nil }
      let(:other_school) { FactoryBot.create(:school) }
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }
      let(:started_on) { Date.new(2026, 3, 20) }

      let!(:existing_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: other_school,
          started_on: Date.new(2025, 8, 1),
          finished_on: Date.new(2026, 3, 10),
          reported_leaving_by_school_id: other_school.id
        )
      end

      it "does not change the previous period" do
        expect { service.register! }.not_to(change { existing_period.reload.finished_on })

        new_period = teacher.ect_at_school_periods.find_by!(school:)
        expect(new_period.started_on).to eq(started_on)
      end
    end
  end
end
