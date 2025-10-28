RSpec.describe MentorAtSchoolPeriods::ChangeLeadProvider, type: :service do
  subject { described_class.new(mentor_at_school_period:, lead_provider:, author:) }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, started_on:) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { mentor_at_school_period.school }

  let(:started_on) { 3.months.ago.to_date }
  let(:author) { FactoryBot.create(:school_user, school_urn: school.urn) }

  let!(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, contract_period:) }

  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on:) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period, started_on:) }

  let(:old_lead_provider) { training_period.lead_provider }
  let(:new_lead_provider) { lead_provider }
  let(:training_programme) { 'provider_led' }

  describe '#call' do
    context 'when no relationship exists with this lead provider' do
      it 'creates a new expression of interest for the current year and assigns it to the new training period' do
        expect { subject.call }.to change(ActiveLeadProvider, :count).by(1)

        new_active_lead_provider = ActiveLeadProvider.last
        expect(new_active_lead_provider.lead_provider).to eq(lead_provider)
        expect(new_active_lead_provider.contract_period).to eq(contract_period)

        new_training_period = mentor_at_school_period.training_periods.ongoing.first
        expect(new_training_period.school_partnership).to be_nil
        expect(new_training_period.training_programme).to eq('provider_led')
      end
    end

    context 'when there is an exiting relationship with this lead provider' do
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

      it 'uses the existing school partnership' do
        expect { subject.call }.not_to change(ActiveLeadProvider, :count)

        new_training_period = mentor_at_school_period.training_periods.ongoing.first
        expect(new_training_period.school_partnership).to eq(school_partnership)
        expect(new_training_period.training_programme).to eq('provider_led')
      end

      context 'when there are existing training periods' do
        it 'closes existing training periods and opens a new training period' do
          expect { subject.call }.to change(TrainingPeriod, :count).by(1)

          expect(training_period.reload.finished_on).to eq(Time.zone.today)
          expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
        end
      end

      context 'when there are no existing training periods' do
        let(:training_period) { nil }

        it 'opens a new training period' do
          expect { subject.call }.to change(TrainingPeriod, :count).by(1)
        end
      end

      context 'when the existing training period has already finished' do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :finished, mentor_at_school_period:, started_on:) }

        it 'opens a new training period' do
          expect { subject.call }.to change(TrainingPeriod, :count).by(1)
        end
      end
    end

    xit 'writes an appropriate event' do
    end
  end
end
