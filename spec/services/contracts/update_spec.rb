describe Contracts::Update do
  subject(:service) { described_class.new(author:, contract:, params:) }

  let(:contract) { FactoryBot.create(:contract, active_lead_provider: ) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }  
  let!(:bands) { FactoryBot.create_list(:active_lead_provider_band, 3, active_lead_provider:) }  
  
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:params) do
    {
      ecf_contract_version: "updated-version",
      banded_fee_structure_attributes: {
        id: contract.banded_fee_structure.id,
        recruitment_target: 9_999,
        bands_attributes: [
          { band_id: bands.first.id, fee_per_declaration: 200, output_fee_percentage: 75, service_fee_percentage: 25 },
          { band_id: bands.second.id, fee_per_declaration: 100, output_fee_percentage: 75, service_fee_percentage: 25 },
          { band_id: bands.third.id, fee_per_declaration: 50, output_fee_percentage: 50, service_fee_percentage: 50 }
        ]
      },
    }
  end

  before { allow(Events::Record).to receive(:record_contract_updated_event!) }

  it "updates the contract and its nested fee structures, records the updated event with modifications, and returns the contract" do
    result = service.call

    expect(result).to eq(contract)
    expect(result.ecf_contract_version).to eq("updated-version")
    expect(result.banded_fee_structure.recruitment_target).to eq(9_999)
    
    expect(contract.banded_fee_structure.bands.first.fee_per_declaration).to eq 200
    expect(contract.banded_fee_structure.bands.second.fee_per_declaration).to eq 100
    expect(contract.banded_fee_structure.bands.third.fee_per_declaration).to eq 50       

    expect(contract.banded_fee_structure.bands.first.output_fee_percentage).to eq 75
    expect(contract.banded_fee_structure.bands.second.output_fee_percentage).to eq 75
    expect(contract.banded_fee_structure.bands.third.output_fee_percentage).to eq 50       
    
    expect(contract.banded_fee_structure.bands.first.service_fee_percentage).to eq 25
    expect(contract.banded_fee_structure.bands.second.service_fee_percentage).to eq 25
    expect(contract.banded_fee_structure.bands.third.service_fee_percentage).to eq 50   
    
    expect(Events::Record).to have_received(:record_contract_updated_event!).with(
      author:,
      contract:,
      modifications: include("ecf_contract_version")
    )
  end
end
