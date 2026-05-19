describe ActiveLeadProviders::CascadeDelete do
  subject(:service) { described_class.new(active_lead_provider:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let!(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:) }
  let(:flat_rate_fee_structure) { contract.flat_rate_fee_structure }
  let(:banded_fee_structure) { contract.banded_fee_structure }
  let!(:statement) { FactoryBot.create(:statement, contract:, active_lead_provider:) }
  let!(:lead_provider_delivery_partnership) do
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
  end

  it "destroys the active lead provider with its contracts, fee structures, bands, statements, and partnerships, leaving delivery partners intact" do
    flat_rate_fee_structure_id = flat_rate_fee_structure.id
    banded_fee_structure_id = banded_fee_structure.id
    band_ids = banded_fee_structure.bands.pluck(:id)
    delivery_partner = lead_provider_delivery_partnership.delivery_partner

    service.call

    expect(ActiveLeadProvider).not_to exist(active_lead_provider.id)
    expect(Contract).not_to exist(contract.id)
    expect(Contract::FlatRateFeeStructure).not_to exist(flat_rate_fee_structure_id)
    expect(Contract::BandedFeeStructure).not_to exist(banded_fee_structure_id)
    expect(Contract::BandedFeeStructure::Band.where(id: band_ids)).not_to exist
    expect(Statement).not_to exist(statement.id)
    expect(LeadProviderDeliveryPartnership).not_to exist(lead_provider_delivery_partnership.id)
    expect(DeliveryPartner).to exist(delivery_partner.id)
  end

  it "wraps the deletions in a transaction" do
    allow(active_lead_provider).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

    expect { service.call }.to raise_error(ActiveRecord::RecordNotDestroyed)
    expect(ActiveLeadProvider).to exist(active_lead_provider.id)
    expect(Contract).to exist(contract.id)
    expect(Statement).to exist(statement.id)
    expect(LeadProviderDeliveryPartnership).to exist(lead_provider_delivery_partnership.id)
  end
end
