describe ActiveLeadProviders::CascadeDelete do
  subject(:service) { described_class.new(active_lead_provider:, author:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let!(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:) }
  let(:flat_rate_fee_structure) { contract.flat_rate_fee_structure }
  let(:banded_fee_structure) { contract.banded_fee_structure }
  let!(:statement) { FactoryBot.create(:statement, contract:, active_lead_provider:) }
  let!(:statement_adjustment) { FactoryBot.create(:statement_adjustment, statement:) }
  let!(:lead_provider_delivery_partnership) do
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
  end
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  before { allow(Events::Record).to receive(:record_active_lead_provider_deleted_event!) }

  it "destroys the active lead provider with its contracts, fee structures, bands, statements, adjustments and partnerships, leaving delivery partners intact, and records the deleted event" do
    flat_rate_fee_structure_id = flat_rate_fee_structure.id
    banded_fee_structure_id = banded_fee_structure.id
    band_term_ids = banded_fee_structure.band_terms.pluck(:id)
    delivery_partner = lead_provider_delivery_partnership.delivery_partner
    lead_provider = active_lead_provider.lead_provider
    contract_period = active_lead_provider.contract_period

    service.call

    expect(ActiveLeadProvider).not_to exist(active_lead_provider.id)
    expect(Contract).not_to exist(contract.id)
    expect(Contract::FlatRateFeeStructure).not_to exist(flat_rate_fee_structure_id)
    expect(Contract::BandedFeeStructure).not_to exist(banded_fee_structure_id)
    expect(Contract::BandedFeeStructure::BandTerm.where(id: band_term_ids)).not_to exist
    expect(Statement).not_to exist(statement.id)
    expect(Statement::Adjustment).not_to exist(statement_adjustment.id)
    expect(LeadProviderDeliveryPartnership).not_to exist(lead_provider_delivery_partnership.id)
    expect(DeliveryPartner).to exist(delivery_partner.id)
    expect(Events::Record).to have_received(:record_active_lead_provider_deleted_event!).with(author:, lead_provider:, contract_period:)
  end

  it "wraps the deletions in a transaction" do
    allow(active_lead_provider).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

    expect { service.call }.to raise_error(ActiveRecord::RecordNotDestroyed)
    expect(ActiveLeadProvider).to exist(active_lead_provider.id)
    expect(Contract).to exist(contract.id)
    expect(Statement).to exist(statement.id)
    expect(LeadProviderDeliveryPartnership).to exist(lead_provider_delivery_partnership.id)
    expect(Events::Record).not_to have_received(:record_active_lead_provider_deleted_event!)
  end

  describe "raising an exception when usage data is present" do
    it "raises when a declaration references one of its statements, destroying nothing" do
      FactoryBot.create(:declaration, active_lead_provider:, payment_statement: statement)

      expect { service.call }.to raise_error(described_class::CascadeDeleteError, "Declarations are present")
      expect(ActiveLeadProvider).to exist(active_lead_provider.id)
    end

    it "raises when a training period references one of its school partnerships, destroying nothing" do
      FactoryBot.create(:training_period, :with_active_lead_provider, active_lead_provider:)

      expect { service.call }.to raise_error(described_class::CascadeDeleteError, "Training periods are present")
      expect(ActiveLeadProvider).to exist(active_lead_provider.id)
    end

    it "raises when an expression of interest references it, destroying nothing" do
      FactoryBot.create(:training_period, :with_only_expression_of_interest, expression_of_interest: active_lead_provider)

      expect { service.call }.to raise_error(described_class::CascadeDeleteError, "Expressions of interest are present")
      expect(ActiveLeadProvider).to exist(active_lead_provider.id)
    end
  end
end
