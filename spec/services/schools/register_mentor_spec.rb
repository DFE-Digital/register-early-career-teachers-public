RSpec.describe Schools::RegisterMentor do
  subject(:service) do
    described_class.new(trs_first_name:,
                        trs_last_name:,
                        corrected_name:,
                        trn:,
                        school_urn: school.urn,
                        email:,
                        lead_provider:,
                        started_on:,
                        author:)
  end

  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:trs_first_name) { "Dusty" }
  let(:trs_last_name) { "Rhodes" }
  let(:corrected_name) { "Randy Marsh" }
  let(:trn) { "3002586" }
  let(:school) { FactoryBot.create(:school) }
  let(:email) { "randy@tegridyfarms.com" }
  let(:started_on) { Date.new(2024, 9, 17) }
  let(:teacher) { subject.teacher }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:mentor_at_school_period) { teacher.mentor_at_school_periods.first }

  describe '#register!' do
    context 'when no ActiveLeadProvider exists for the registration period' do
      it 'raises an error' do
        expect { service.register! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when provider-led' do
      let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

      context "when a Teacher record with the same trn doesn't exist" do
        it 'creates a new Teacher record' do
          expect { service.register! }.to change(Teacher, :count).from(0).to(1)
          expect(teacher.trs_first_name).to eq(trs_first_name)
          expect(teacher.trs_last_name).to eq(trs_last_name)
          expect(teacher.corrected_name).to eq(corrected_name)
          expect(teacher.trn).to eq(trn)
        end

        it 'creates an associated MentorATSchoolPeriod record' do
          expect { service.register! }.to change(MentorAtSchoolPeriod, :count).from(0).to(1)
          expect(mentor_at_school_period.teacher_id).to eq(Teacher.first.id)
          expect(mentor_at_school_period.started_on).to eq(started_on)
          expect(mentor_at_school_period.email).to eq(email)
        end
      end

      context "when a Teacher record with the same trn exists" do
        let!(:teacher) { FactoryBot.create(:teacher, trn:) }

        context "without MentorATSchoolPeriod records" do
          it { expect { service.register! }.not_to change(Teacher, :count) }
        end

        context "with MentorATSchoolPeriod records" do
          before { FactoryBot.create(:mentor_at_school_period, teacher:) }

          it { expect { service.register! }.to raise_error(ActiveRecord::RecordInvalid) }
        end
      end

      context 'when no SchoolPartnerships exist' do
        it 'creates a TrainingPeriod linked to the MentorAtSchoolPeriod and with an expression of interest for the ActiveLeadProvider' do
          expect { service.register! }.to change(TrainingPeriod, :count).by(1)

          training_period = TrainingPeriod.find_by!(started_on:)

          expect(training_period.mentor_at_school_period.teacher).to eq(teacher)
          expect(training_period.mentor_at_school_period).to eq(mentor_at_school_period)
          expect(training_period.started_on).to eq(started_on)
          expect(training_period.expression_of_interest).to eq(active_lead_provider)
          expect(training_period.school_partnership).to be_nil
          expect(training_period.training_programme).to eql('provider_led')
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

      describe 'recording an event' do
        before { allow(Events::Record).to receive(:record_teacher_registered_as_mentor_event!).with(any_args).and_call_original }

        it 'records a mentor_registered event with the expected attributes' do
          service.register!

          expect(Events::Record).to have_received(:record_teacher_registered_as_mentor_event!).with(
            hash_including(author:, mentor_at_school_period:, teacher:, school:)
          )
        end
      end

      context "when no start date is provided" do
        subject(:service) do
          described_class.new(trs_first_name:,
                              trs_last_name:,
                              corrected_name:,
                              trn:,
                              school_urn: school.urn,
                              email:,
                              author:)
        end

        it "current date is assigned" do
          service.register!

          expect(mentor_at_school_period.started_on).to eq(Date.current)
        end
      end
    end

    context 'when school-led' do
      let(:lead_provider) { nil }

      it 'does not create a TrainingPeriod' do
        expect { service.register! }.not_to change(TrainingPeriod, :count)
      end
    end
  end
end
