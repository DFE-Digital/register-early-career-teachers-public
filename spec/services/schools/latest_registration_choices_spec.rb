describe Schools::LatestRegistrationChoices do
  let(:service) { Schools::LatestRegistrationChoices.new(school:, contract_period:) }

  let(:contract_period) { create(:contract_period, year: 2025) }
  let(:delivery_partner) { create(:delivery_partner) }

  describe '#lead_provider_and_delivery_partner' do
    subject { service.lead_provider_and_delivery_partner }

    context 'when there is no last_chosen_lead_provider present on the school' do
      let(:lead_provider) { create(:lead_provider) }
      let(:school) { create(:school, last_chosen_lead_provider: nil) }

      it { is_expected.to be_nil }
    end

    context 'when there is a last_chosen_lead_provider present on the school' do
      let(:school) { create(:school, :provider_led_last_chosen) }
      let(:lead_provider) { school.last_chosen_lead_provider }

      context 'when the last_chosen_lead_provider is in a partnership with the school' do
        let!(:school_partnership) { create(:school_partnership, lead_provider_delivery_partnership:, school:) }
        let!(:lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
        let!(:active_lead_provider) { create(:active_lead_provider, lead_provider:, contract_period:) }

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
        let(:previous_contract_period) { create(:contract_period, year: 2024) }

        context 'when the last_chosen_lead_provider is active' do
          let!(:active_lead_provider) { create(:active_lead_provider, lead_provider:, contract_period:) }

          it 'is the last chosen lead provider' do
            expect(subject.lead_provider).to eql(lead_provider)
          end

          it 'returns no delivery partner' do
            expect(subject.delivery_partner).to be_nil
          end
        end

        context 'when the last_chosen_lead_provider is inactive' do
          let!(:active_lead_provider) { create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period) }

          it { is_expected.to be_nil }
        end
      end

      context 'when the school is partnered with the same lead provider and multiple delivery partners' do
        let!(:active_lead_provider) { create(:active_lead_provider, lead_provider:, contract_period:) }

        let(:earliest_delivery_partner) { create(:delivery_partner) }
        let!(:earliest_lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner: earliest_delivery_partner) }
        let!(:earliest_school_partnership) { create(:school_partnership, lead_provider_delivery_partnership: earliest_lead_provider_delivery_partnership, school:, created_at: 2.weeks.ago) }

        let(:latest_delivery_partner) { create(:delivery_partner) }
        let!(:latest_lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner: latest_delivery_partner) }
        let!(:latest_school_partnership) { create(:school_partnership, school:, lead_provider_delivery_partnership: latest_lead_provider_delivery_partnership, created_at: 1.week.ago) }

        it 'uses the earliest partnership' do
          expect(subject.lead_provider).to eql(lead_provider)
          expect(subject.delivery_partner).to eql(earliest_delivery_partner)
        end
      end
    end
  end

  describe '#appropriate_body' do
    context 'when there is a last_chosen_appropriate_body present on the school' do
      subject { service.appropriate_body }

      let(:appropriate_body) { create(:appropriate_body) }
      let(:school) { create(:school, last_chosen_appropriate_body: appropriate_body) }

      it('returns the last chosen appropriate body') { is_expected.to eql(appropriate_body) }
    end

    context 'when there is no last_chosen_appropriate_body present on the school' do
      subject { service.appropriate_body }

      let(:school) { create(:school, last_chosen_appropriate_body: nil) }

      it { is_expected.to be_nil }
    end
  end
end
