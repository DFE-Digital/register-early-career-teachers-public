describe Contracts::Destroy do
  subject(:service) { described_class.new(author:, contract:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:contract) do
    FactoryBot.create(:contract, :for_ecf, :with_bands_and_band_terms,
                      active_lead_provider:)
  end

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  before { allow(Events::Record).to receive(:record_contract_deleted_event!) }

  it "destroys the contract, its banded fee structure and band terms, and records the deleted event" do
    banded_fee_structure_id = contract.banded_fee_structure.id
    band_term_ids = contract.banded_fee_structure.band_terms.pluck(:id)

    service.call

    expect(Contract).not_to exist(contract.id)
    expect(Contract::BandedFeeStructure).not_to exist(banded_fee_structure_id)
    expect(Contract::BandedFeeStructure::BandTerm.where(id: band_term_ids)).not_to exist
    expect(Events::Record).to have_received(:record_contract_deleted_event!).with(author:, active_lead_provider:)
  end

  context "when the contract has statements" do
    before { FactoryBot.create(:statement, contract:, active_lead_provider:) }

    it "raises a DeletionError and does not destroy the contract" do
      expect { service.call }.to raise_error(Contracts::Destroy::DeletionError, "Cannot delete a contract that has statements")

      expect(Contract).to exist(contract.id)
    end
  end
end
