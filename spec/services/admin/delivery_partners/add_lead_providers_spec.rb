RSpec.describe Admin::DeliveryPartners::AddLeadProviders do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:year) { contract_period.year }

  let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }

  let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
  let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

  let(:service) do
    described_class.new(
      delivery_partner_id: delivery_partner.id,
      year:,
      lead_provider_ids:,
      author:
    )
  end

  describe '#call' do
    context 'when all parameters are valid' do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s, active_lead_provider_2.id.to_s] }

      it 'executes successfully without raising an exception' do
        expect { service.call }.not_to raise_error
      end

      it 'creates lead provider delivery partnerships' do
        expect { service.call }.to change(LeadProviderDeliveryPartnership, :count).by(2)
      end

      it 'calls the UpdateLeadProviderPairings service' do
        expect(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).with(
          delivery_partner:,
          contract_period:,
          active_lead_provider_ids: [active_lead_provider_1.id, active_lead_provider_2.id],
          author:
        ).and_call_original

        service.call
      end
    end

    context 'when delivery partner does not exist' do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }

      before do
        delivery_partner.destroy
      end

      it 'raises a ValidationError' do
        expect { service.call }.to raise_error(described_class::ValidationError, "Delivery partner not found")
      end
    end

    context 'when contract period does not exist' do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }
      let(:year) { 2099 }

      it 'raises a ValidationError' do
        expect { service.call }.to raise_error(described_class::ValidationError, "Contract period for year 2099 not found")
      end
    end

    context 'when lead provider IDs are empty' do
      let(:lead_provider_ids) { [] }

      it 'raises a NoLeadProvidersSelectedError' do
        expect { service.call }.to raise_error(described_class::NoLeadProvidersSelectedError, "Select at least one lead provider")
      end
    end

    context 'when lead provider IDs contain blank values' do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s, "", "   ", active_lead_provider_2.id.to_s] }

      it 'filters out blank values and succeeds' do
        expect { service.call }.not_to raise_error
      end

      it 'creates partnerships only for non-blank IDs' do
        expect { service.call }.to change(LeadProviderDeliveryPartnership, :count).by(2)
      end
    end

    context 'when lead provider IDs only contain blank values' do
      let(:lead_provider_ids) { ["", "   ", nil] }

      it 'raises a NoLeadProvidersSelectedError' do
        expect { service.call }.to raise_error(described_class::NoLeadProvidersSelectedError, "Select at least one lead provider")
      end
    end

    context 'when UpdateLeadProviderPairings service fails' do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }

      before do
        update_service_double = instance_double(DeliveryPartners::UpdateLeadProviderPairings)
        allow(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).and_return(update_service_double)
        allow(update_service_double).to receive(:update!).and_return(false)
      end

      it 'raises a ValidationError' do
        expect { service.call }.to raise_error(described_class::ValidationError, "Unable to update lead provider partners")
      end
    end

    context 'when an unexpected error occurs' do
      let(:lead_provider_ids) { [active_lead_provider_1.id.to_s] }

      before do
        update_service_double = instance_double(DeliveryPartners::UpdateLeadProviderPairings)
        allow(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).and_return(update_service_double)
        allow(update_service_double).to receive(:update!).and_raise(StandardError, "Something went wrong")
      end

      it 'lets the exception bubble up' do
        expect { service.call }.to raise_error(StandardError, "Something went wrong")
      end
    end
  end
end
