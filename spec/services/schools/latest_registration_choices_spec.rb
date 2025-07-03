describe Schools::LatestRegistrationChoices do
  let(:service) { Schools::LatestRegistrationChoices.new(school:, registration_period:) }

  let(:registration_period) { FactoryBot.create(:registration_period, year: 2025) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  describe '#lead_provider_and_delivery_partner' do
    subject { service.lead_provider_and_delivery_partner }

    context 'when there is no last_chosen_lead_provider present on the school' do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:school) { FactoryBot.create(:school, last_chosen_lead_provider: nil) }

      it { is_expected.to be_nil }
    end

    context 'when there is a last_chosen_lead_provider present on the school' do
      let(:school) { FactoryBot.create(:school, :provider_led_last_chosen) }
      let(:lead_provider) { school.last_chosen_lead_provider }

      context 'when the last_chosen_lead_provider is in a partnership with the school' do
        let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }
        let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
        let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:) }

        it 'returns a Schools::LatestRegistrationChoices::Choice' do
          expect(subject).to be_a(Schools::LatestRegistrationChoices::Choice)
        end

        it 'returns the last chosen lead provider' do
          expect(subject.lead_provider).to eql(lead_provider)
        end

        it 'returns the associated delivery partner' do
          expect(subject.delivery_partner).to eql(delivery_partner)
        end
      end

      context 'when the last_chosen_lead_provider is not currently in a partnership with the school' do
        let(:previous_registration_period) { FactoryBot.create(:registration_period, year: 2024) }

        context 'when the last_chosen_lead_provider is active' do
          let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:) }

          it 'is the last chosen lead provider' do
            expect(subject.lead_provider).to eql(lead_provider)
          end

          it 'returns no delivery partner' do
            expect(subject.delivery_partner).to be_nil
          end
        end

        context 'when the last_chosen_lead_provider is inactive' do
          let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, registration_period: previous_registration_period) }

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '#appropriate_body' do
    context 'when there is a last_chosen_appropriate_body present on the school' do
      subject { service.appropriate_body }

      let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
      let(:school) { FactoryBot.create(:school, last_chosen_appropriate_body: appropriate_body) }

      it('returns the last chosen appropriate body') { is_expected.to eql(appropriate_body) }
    end

    context 'when there is no last_chosen_appropriate_body present on the school' do
      subject { service.appropriate_body }

      let(:school) { FactoryBot.create(:school, last_chosen_appropriate_body: nil) }

      it { is_expected.to be_nil }
    end
  end
end
