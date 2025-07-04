describe LeadProviders::Active do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  describe 'initialization' do
    it 'is initialized with a lead provider' do
      service = LeadProviders::Active.new(lead_provider)

      expect(service.lead_provider).to eql(lead_provider)
    end
  end

  describe '#active_in_contract_period?' do
    subject { LeadProviders::Active.new(lead_provider).active_in_contract_period?(contract_period) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period) }

    context 'when an active_lead_provider record exists for the registration period' do
      let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

      it { is_expected.to be(true) }
    end

    context 'when no active_lead_provider record exists for the registration period' do
      it { is_expected.to be(false) }
    end
  end
end
