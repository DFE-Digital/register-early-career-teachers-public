RSpec.describe MentorAtSchoolPeriods::ChangeLeadProvider, type: :service do
  subject { described_class.call(mentor_at_school_period, new_lead_provider: lead_provider, old_lead_provider:, author:) }

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

  let(:old_lead_provider) { training_period.lead_provider }
  let(:new_lead_provider) { lead_provider }

  describe '#call' do
    context 'when the new lead provider is the same as the old lead provider' do
      let(:lead_provider) { old_lead_provider }

      it 'raises an error' do
        expect { subject }.to raise_error(Teachers::SwitchLeadProviderHelper::LeadProviderNotChangedError)

        expect(training_period.finished_on).to be_nil
      end
    end

    context 'when there is no school partnership with the new lead provider' do
      it 'creates a new expression of interest for the current year and assigns it to the new training period' do
        expect { subject }.to change(ActiveLeadProvider, :count).by(1)

        new_active_lead_provider = ActiveLeadProvider.last
        expect(new_active_lead_provider.lead_provider).to eq(lead_provider)
        expect(new_active_lead_provider.contract_period).to eq(contract_period)

        new_training_period = mentor_at_school_period.training_periods.ongoing.first
        expect(new_training_period.school_partnership).to be_nil
        expect(new_training_period.training_programme).to eq('provider_led')
      end
    end

    context 'when there is a school partnership with the new lead provider' do
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

      it 'uses the existing school partnership' do
        expect { subject }.not_to change(ActiveLeadProvider, :count)

        new_training_period = mentor_at_school_period.training_periods.ongoing.first
        expect(new_training_period.school_partnership).to eq(school_partnership)
        expect(new_training_period.training_programme).to eq('provider_led')
      end

      context 'when there are existing training periods' do
        context 'when the training period started in the past' do
          it 'closes existing training periods and opens a new training period' do
            expect { subject }.to change(TrainingPeriod, :count).by(1)

            expect(training_period.reload.finished_on).to eq(Time.zone.today)
          end
        end

        context 'when the training period started today' do
          let(:started_on) { Date.current }

          it 'closes existing periods and starts a new one' do
            expect { subject }.to change(TrainingPeriod, :count).by(1)

            expect(training_period.reload.finished_on).to eq(Time.zone.today)
          end
        end
      end

      context 'when there are no existing training periods' do
        let(:training_period) { nil }
        let(:old_lead_provider) { FactoryBot.create(:lead_provider) }

        it 'opens a new training period' do
          expect { subject }.to change(TrainingPeriod, :count).by(1)
        end
      end

      context 'when the existing training period has already finished' do
        let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :finished, mentor_at_school_period:, started_on:) }

        it 'opens a new training period' do
          expect { subject }.to change(TrainingPeriod, :count).by(1)
        end
      end
    end

    context 'when there is no school partnership with the old lead provider' do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :for_mentor,
                          :ongoing,
                          :with_only_expression_of_interest,
                          mentor_at_school_period:,
                          started_on:)
      end
      let(:old_lead_provider) { FactoryBot.create(:lead_provider) }

      it 'deletes the existing training period' do
        expect { subject }.not_to change(TrainingPeriod, :count)
      end
    end

    it "records an event" do
      freeze_time

      expect(Events::Record)
        .to receive(:record_teacher_training_lead_provider_updated_event!)
        .with(
          old_lead_provider_name: old_lead_provider.name,
          new_lead_provider_name: new_lead_provider.name,
          author:,
          ect_at_school_period: nil,
          mentor_at_school_period:,
          school:,
          teacher:,
          happened_at: Time.current
        )

      subject
    end
  end
end
