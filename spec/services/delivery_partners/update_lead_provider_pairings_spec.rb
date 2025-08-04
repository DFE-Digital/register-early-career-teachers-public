RSpec.describe DeliveryPartners::UpdateLeadProviderPairings do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
  let!(:lead_provider_3) { FactoryBot.create(:lead_provider, name: "Lead Provider 3") }

  let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
  let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }
  let!(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_3, contract_period:) }

  let(:service) do
    described_class.new(
      delivery_partner:,
      contract_period:,
      active_lead_provider_ids: new_active_lead_provider_ids,
      author:
    )
  end

  describe '#update!' do
    context 'when adding new partnerships' do
      let(:new_active_lead_provider_ids) { [active_lead_provider_1.id, active_lead_provider_2.id] }

      it 'creates new lead provider delivery partnerships' do
        expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(2)

        partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
        expect(partnerships.map(&:active_lead_provider_id)).to contain_exactly(active_lead_provider_1.id, active_lead_provider_2.id)
      end

      it 'records partnership added events' do
        expect(Events::Record).to receive(:record_lead_provider_delivery_partnership_added_event!).twice

        service.update!
      end

      it 'returns true on success' do
        expect(service.update!).to be true
      end
    end

    context 'when adding to existing partnerships' do
      let!(:existing_partnership_1) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          delivery_partner:,
          active_lead_provider: active_lead_provider_1
        )
      end

      let(:new_active_lead_provider_ids) { [active_lead_provider_2.id, active_lead_provider_3.id] }

      it 'adds new partnerships without removing existing ones' do
        expect { service.update! }.to change(LeadProviderDeliveryPartnership, :count).by(2)

        partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
        expect(partnerships.map(&:active_lead_provider_id)).to contain_exactly(
          active_lead_provider_1.id,
          active_lead_provider_2.id,
          active_lead_provider_3.id
        )
      end

      it 'records only added events' do
        expect(Events::Record).to receive(:record_lead_provider_delivery_partnership_added_event!).twice

        service.update!
      end
    end

    context 'when no new partnerships to add' do
      let!(:existing_partnership_1) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          delivery_partner:,
          active_lead_provider: active_lead_provider_1
        )
      end

      let(:new_active_lead_provider_ids) { [active_lead_provider_1.id] }

      it 'does not change partnerships' do
        expect { service.update! }.not_to change(LeadProviderDeliveryPartnership, :count)
      end

      it 'does not record any events' do
        expect(Events::Record).not_to receive(:record_lead_provider_delivery_partnership_added_event!)

        service.update!
      end

      it 'returns true' do
        expect(service.update!).to be true
      end
    end

    context 'when there is a database error' do
      let(:new_active_lead_provider_ids) { [active_lead_provider_1.id] }

      before do
        allow(LeadProviderDeliveryPartnership).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(LeadProviderDeliveryPartnership.new))
      end

      it 'returns false on error' do
        expect(service.update!).to be false
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to update lead provider pairings/)
        service.update!
      end
    end
  end
end
