RSpec.describe Schools::CreateMentorTrainingPeriod do
  subject(:service) do
    described_class.new(
      mentor_at_school_period:,
      lead_provider:,
      started_on:,
      author:
    )
  end

  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:started_on) { mentor_at_school_period.started_on }
  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }
  let(:contract_period) { FactoryBot.create(:contract_period) }

  before do
    allow(ContractPeriod).to receive(:containing_date).with(started_on).and_return(contract_period)
  end

  describe '#create!' do
    context 'when there is a confirmed school partnership' do
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

      it 'creates a training period linked to the school partnership' do
        expect { service.create! }.to change(TrainingPeriod, :count).by(1)

        training_period = TrainingPeriod.last
        expect(training_period.mentor_at_school_period).to eq(mentor_at_school_period)
        expect(training_period.school_partnership).to eq(school_partnership)
        expect(training_period.expression_of_interest).to be_nil
        expect(training_period.training_programme).to eq('provider_led')
        expect(training_period.started_on).to eq(started_on)
      end

      it 'creates a teacher_starts_training_period event' do
        allow(Events::Record).to receive(:record_teacher_starts_training_period_event!).and_call_original

        service.create!

        expect(Events::Record).to have_received(:record_teacher_starts_training_period_event!).with(
          hash_including(
            author:,
            teacher: mentor_at_school_period.teacher,
            school:,
            training_period: TrainingPeriod.last,
            mentor_at_school_period:,
            ect_at_school_period: nil,
            happened_at: started_on
          )
        )
      end
    end

    context 'when there is no confirmed school partnership' do
      let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

      it 'creates a training period linked to an expression of interest' do
        expect { service.create! }.to change(TrainingPeriod, :count).by(1)

        training_period = TrainingPeriod.last
        expect(training_period.mentor_at_school_period).to eq(mentor_at_school_period)
        expect(training_period.school_partnership).to be_nil
        expect(training_period.expression_of_interest).to eq(active_lead_provider)
        expect(training_period.training_programme).to eq('provider_led')
        expect(training_period.started_on).to eq(started_on)
      end

      it 'creates a teacher_starts_training_period event' do
        allow(Events::Record).to receive(:record_teacher_starts_training_period_event!).and_call_original

        service.create!

        expect(Events::Record).to have_received(:record_teacher_starts_training_period_event!).with(
          hash_including(
            author:,
            teacher: mentor_at_school_period.teacher,
            school:,
            training_period: TrainingPeriod.last,
            mentor_at_school_period:,
            ect_at_school_period: nil,
            happened_at: started_on
          )
        )
      end
    end

    context 'when the lead provider is not active for the contract period' do
      it 'raises an error' do
        expect { service.create! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
