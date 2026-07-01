describe Contracts::Create do
  subject(:service) { described_class.new(author:, active_lead_provider:, params:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:params) do
    {
      contract_type: "ittecf_ectp",
      ecf_contract_version: "1",
      ecf_mentor_contract_version: "2",
      banded_fee_structure_attributes: {
        recruitment_target: 1_000,
        uplift_fee_per_declaration: 50,
        monthly_service_fee: 5_000,
        setup_fee: 10_000,
        bands_attributes: [
          { min_declarations: 1, max_declarations: 100, fee_per_declaration: 200, output_fee_ratio: 0.75, service_fee_ratio: 0.25 },
        ],
      },
      flat_rate_fee_structure_attributes: {
        recruitment_target: 500,
        fee_per_declaration: 100,
      },
    }
  end

  before { allow(Events::Record).to receive(:record_contract_created_event!) }

  it "creates and returns a contract for the active lead provider, and records the created event" do
    contract = nil
    expect { contract = service.call }.to change(Contract, :count).by(1)

    expect(contract).to be_persisted
    expect(contract.active_lead_provider).to eq(active_lead_provider)
    expect(contract.banded_fee_structure).to have_attributes(recruitment_target: 1_000)
    expect(contract.banded_fee_structure.bands.size).to eq(1)
    expect(contract.flat_rate_fee_structure).to have_attributes(recruitment_target: 500)
    expect(Events::Record).to have_received(:record_contract_created_event!).with(author:, contract:)
  end
end
