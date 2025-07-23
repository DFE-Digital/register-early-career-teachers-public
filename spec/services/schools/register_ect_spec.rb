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
  let(:teacher) { subject.teacher }
  let(:ect_at_school_period) { teacher.ect_at_school_periods.first }
  let!(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }

  describe '#register!' do
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

        context "when a Teacher record with the same TRN don't exist" do
          let(:teacher) { Teacher.first }

          it 'creates a new Teacher record' do
            expect { service.register! }.to change(Teacher, :count).from(0).to(1)
            expect(teacher.trs_first_name).to eq(trs_first_name)
            expect(teacher.trs_last_name).to eq(trs_last_name)
            expect(teacher.trn).to eq(trn)
            expect(teacher.corrected_name).to eq(corrected_name)
          end
        end

        context "when a Teacher record with the same TRN exists but has no ect records" do
          let!(:another_teacher) { FactoryBot.create(:teacher, trn:) }

          it "doesn't create a new Teacher record" do
            expect { service.register! }.not_to change(Teacher, :count)
          end
        end

        context "when a Teacher record with the same TRN exists and has ect records" do
          let(:teacher) { FactoryBot.create(:teacher, trn:) }

          before { FactoryBot.create(:ect_at_school_period, teacher:) }

          it "raise an exception" do
            expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end

        it 'creates an associated ECTAtSchoolPeriod record' do
          expect { service.register! }.to change(ECTAtSchoolPeriod, :count).from(0).to(1)
          expect(ect_at_school_period.teacher_id).to eq(Teacher.first.id)
          expect(ect_at_school_period.started_on).to eq(started_on)
          expect(ect_at_school_period.working_pattern).to eq(working_pattern)
          expect(ect_at_school_period.email).to eq(email)
          expect(ect_at_school_period.school_reported_appropriate_body_id).to eq(school_reported_appropriate_body.id)
          expect(ect_at_school_period.training_programme).to eq(training_programme)
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
      end
    end

    context 'when school-led' do
      let(:training_programme) { 'school_led' }
      let(:lead_provider) { nil }

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
  end
end
