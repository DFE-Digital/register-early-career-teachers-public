RSpec.describe Schools::RegisterECT do
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
                        author:)
  end

  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:school_reported_appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:corrected_name) { "Randy Marsh" }
  let(:email) { "randy@tegridyfarms.com" }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { Date.new(2024, 9, 17) }
  let(:trn) { "3002586" }
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:working_pattern) { "full_time" }
  let(:ect_at_school_period) { subject.teacher.ect_at_school_periods.first }
  let!(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, year: 2024) }

  around do |example|
    travel_to(started_on + 1.day) do
      example.run
    end
  end

  describe '#register!' do
    context "when a Teacher record with the same TRN does not exist" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:training_programme) { 'provider_led' }

      before { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

      it "creates a new Teacher record" do
        expect { service.register! }.to change(Teacher, :count).by(1)

        created_teacher = Teacher.find_by(trn:)
        expect(created_teacher.trs_first_name).to eq(trs_first_name)
        expect(created_teacher.trs_last_name).to eq(trs_last_name)
        expect(created_teacher.corrected_name).to eq(corrected_name)
        expect(created_teacher.api_ect_training_record_id).to be_present
      end
    end

    context 'when provider led' do
      let(:training_programme) { 'provider_led' }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }

      context 'when no ActiveLeadProvider exists for the contract_period' do
        it 'raises an error' do
          expect { service.register! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when provider-led' do
        let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
        let!(:teacher) { FactoryBot.create(:teacher, trn:) }

        context "when a Teacher record with the same TRN exists but has no ect records" do
          it "doesn't create a new Teacher record" do
            expect { service.register! }.not_to change(Teacher, :count)
          end
        end

        context "when a Teacher record with the same TRN exists and has ect records at a different school" do
          let(:other_school) { FactoryBot.create(:school) }

          before { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school: other_school, started_on: Date.new(2024, 1, 1)) }

          it "allows registration (school transfer)" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)
          end
        end

        context "when a Teacher record with the same TRN exists and has ect records at the same school" do
          before { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:, started_on: Date.new(2024, 1, 1)) }

          it "raises an exception" do
            expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end

        context "when a Teacher record with the same TRN exists and has multiple ect records at different schools" do
          let(:school_one) { FactoryBot.create(:school) }
          let(:school_two) { FactoryBot.create(:school) }
          let(:started_on) { Date.current + 1.month }
          let!(:future_contract_period) { FactoryBot.create(:contract_period, :with_schedules, year: started_on.year) }
          let!(:future_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: future_contract_period) }

          before do
            # Create finished periods at two different schools with non-overlapping dates
            FactoryBot.create(:ect_at_school_period, :finished, teacher:, school: school_one, started_on: Date.current - 2.years, finished_on: Date.current - 18.months)
            FactoryBot.create(:ect_at_school_period, :finished, teacher:, school: school_two, started_on: Date.current - 12.months, finished_on: Date.current - 6.months)
          end

          it "allows registration at a third school (multiple transfers)" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

            expect(teacher.ect_at_school_periods.count).to eq(3) # 2 existing + 1 new
          end
        end

        context "when a Teacher record with the same TRN has an ongoing period at different school and finished period at current school" do
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
            expect(ongoing_period.finished_on).to eq(started_on)

            # New period at current school should be created
            new_period = teacher.ect_at_school_periods.find_by(school:, finished_on: nil)
            expect(new_period.started_on).to eq(started_on)
          end
        end

        context "when a Teacher record with the same TRN has a future period at different school" do
          let(:other_school) { FactoryBot.create(:school) }
          let(:started_on) { Date.new(2025, 8, 1) + 1.year }
          let!(:future_contract_period) { FactoryBot.create(:contract_period, :with_schedules, year: started_on.year) }
          let!(:future_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: future_contract_period) }

          before do
            # Future period at other school
            FactoryBot.create(:ect_at_school_period, teacher:, school: other_school, started_on: Date.current + 1.month, finished_on: Date.current + 2.months)
          end

          it "allows registration with non-overlapping future date" do
            expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)
          end
        end

        it 'creates an associated ECTAtSchoolPeriod record' do
          expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

          expect(ect_at_school_period.teacher_id).to eq(Teacher.find_by(trn:).id)
          expect(ect_at_school_period.started_on).to eq(started_on)
          expect(ect_at_school_period.working_pattern).to eq(working_pattern)
          expect(ect_at_school_period.email).to eq(email)
          expect(ect_at_school_period.school_reported_appropriate_body_id).to eq(school_reported_appropriate_body.id)
        end

        describe 'recording an event' do
          before { allow(Events::Record).to receive(:record_teacher_registered_as_ect_event!).with(any_args).and_call_original }

          it 'records a mentor_registered event with the expected attributes' do
            service.register!

            expect(Events::Record).to have_received(:record_teacher_registered_as_ect_event!).with(
              hash_including(author:, ect_at_school_period:, teacher:, school:)
            )
          end
        end

        it 'sets ab and provider choices for the school' do
          expect { service.register! }
            .to change(school, :last_chosen_appropriate_body_id)
                  .to(school_reported_appropriate_body.id)
                  .and change(school, :last_chosen_training_programme)
                        .to(training_programme)
                        .and change(school, :last_chosen_lead_provider_id).to(lead_provider.id)
        end

        context 'when no SchoolPartnerships exist' do
          it 'creates a TrainingPeriod linked to the ECTAtSchoolPeriod and with an expression of interest for the ActiveLeadProvider' do
            expect { service.register! }.to change(TrainingPeriod, :count).by(1)

            training_period = TrainingPeriod.find_by!(started_on:)

            expect(training_period.ect_at_school_period.teacher).to eq(teacher)
            expect(training_period.ect_at_school_period).to eq(ect_at_school_period)
            expect(training_period.started_on).to eq(started_on)
            expect(training_period.expression_of_interest).to eq(active_lead_provider)
            expect(training_period.school_partnership).to be_nil
            expect(training_period.training_programme).to eq(training_programme)
          end
        end

        context 'when a SchoolPartnership exists' do
          let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
          let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
          let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

          it 'creates a TrainingPeriod with a school_partnership and no expression_of_interest' do
            expect { service.register! }.to change(TrainingPeriod, :count).by(1)

            training_period = TrainingPeriod.find_by!(started_on:)

            expect(training_period.expression_of_interest).to be_nil
            expect(training_period.school_partnership).to eq(school_partnership)
          end
        end

        it 'calls `Teachers::SetFundingEligibility` service with correct params' do
          allow(Teachers::SetFundingEligibility).to receive(:new).and_call_original

          service.register!

          expect(Teachers::SetFundingEligibility).to have_received(:new).with(teacher:, author:)
        end
      end
    end

    context 'when school-led' do
      let(:training_programme) { 'school_led' }
      let(:lead_provider) { nil }

      before do
        FactoryBot.create(:teacher, trn:)
      end

      it 'creates a TrainingPeriod' do
        expect { service.register! }.to change(TrainingPeriod, :count).by(1)
      end

      it 'has no expression of interest or school partnership' do
        service.register!

        training_period = TrainingPeriod.find_by!(started_on:)

        expect(training_period.school_partnership).to be_nil
        expect(training_period.expression_of_interest).to be_nil
      end

      it 'has training programme: school_led' do
        service.register!

        training_period = TrainingPeriod.find_by!(started_on:)

        expect(training_period.training_programme).to eql('school_led')
      end
    end

    context 'when switching from provider-led to school-led' do
      let(:training_programme) { 'school_led' }
      let(:lead_provider) { nil }

      before do
        school.update!(
          last_chosen_lead_provider: FactoryBot.create(:lead_provider),
          last_chosen_training_programme: 'provider_led',
          last_chosen_appropriate_body: nil
        )
      end

      it 'updates the last chosen fields correctly' do
        expect { service.register! }
          .to change { school.reload.last_chosen_lead_provider_id }.to(nil)
           .and change { school.reload.last_chosen_training_programme }.to('school_led')
           .and change { school.reload.last_chosen_appropriate_body }.to(school_reported_appropriate_body)
      end
    end

    context 'when ECT is transferring from another school' do
      let(:training_programme) { 'school_led' }
      let(:lead_provider) { nil }
      let(:other_school) { FactoryBot.create(:school) }
      let!(:teacher) { FactoryBot.create(:teacher, trn:) }

      let!(:existing_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: other_school,
          started_on: Date.new(2024, 1, 1),
          finished_on: nil
        )
      end

      it 'closes the ongoing ECT period at the previous school' do
        expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
          ect_at_school_period: existing_period,
          finished_on: started_on,
          author:
        ).and_call_original

        service.register!

        existing_period.reload
        expect(existing_period.finished_on).to eq(started_on)
      end

      it 'allows registration at the new school' do
        expect { service.register! }.to change(ECTAtSchoolPeriod, :count).by(1)

        new_period = teacher.ect_at_school_periods.find_by(school:)
        expect(new_period.started_on).to eq(started_on)
      end

      context 'when transfer happens today' do
        let(:started_on) { Date.current }

        it 'closes ongoing periods that started on or before today' do
          expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
            ect_at_school_period: existing_period,
            finished_on: started_on,
            author:
          ).and_call_original

          service.register!

          existing_period.reload
          expect(existing_period.finished_on).to eq(started_on)
        end
      end

      context 'when period 1 started before today and period 2 starts today' do
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

        it 'closes the existing period that started before today when new period starts today' do
          expect(ECTAtSchoolPeriods::Finish).to receive(:new).with(
            ect_at_school_period: existing_period,
            finished_on: started_on,
            author:
          ).and_call_original

          service.register!

          existing_period.reload
          expect(existing_period.finished_on).to eq(started_on)

          new_period = teacher.ect_at_school_periods.find_by(school:)
          expect(new_period.started_on).to eq(started_on)
          expect(new_period.finished_on).to be_nil
        end
      end
    end
  end
end
