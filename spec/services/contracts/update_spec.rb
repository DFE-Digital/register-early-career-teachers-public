describe Contracts::Update do
  subject(:service) { described_class.new(author:, contract:, params:) }

  let(:contract) { FactoryBot.create(:contract) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:params) do
    {
      ecf_contract_version: "updated-version",
      banded_fee_structure_attributes: {
        id: contract.banded_fee_structure.id,
        recruitment_target: 9_999,
      },
    }
  end

  before { allow(Events::Record).to receive(:record_contract_updated_event!) }

  it "updates the contract and its nested fee structures, records the updated event with modifications, and returns the contract" do
    result = service.call

    expect(result).to eq(contract)
    expect(result.ecf_contract_version).to eq("updated-version")
    expect(result.banded_fee_structure.recruitment_target).to eq(9_999)
    expect(Events::Record).to have_received(:record_contract_updated_event!).with(
      author:,
      contract:,
      modifications: include("ecf_contract_version")
    )
  end
end
