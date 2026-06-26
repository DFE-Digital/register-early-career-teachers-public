describe Contracts::Create do
  subject(:service) { described_class.new(author:, active_lead_provider:, params:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  
  
  let!(:bands) { FactoryBot.create_list(:active_lead_provider_band, 3, active_lead_provider:) }  
  # let(:active_lead_provider_band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }
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
          { band_id: bands.first.id, fee_per_declaration: 200, output_fee_percentage: 75, service_fee_percentage: 25 },
          { band_id: bands.second.id, fee_per_declaration: 100, output_fee_percentage: 75, service_fee_percentage: 25 },
          { band_id: bands.third.id, fee_per_declaration: 50, output_fee_percentage: 50, service_fee_percentage: 50 }
        ]
      },
      flat_rate_fee_structure_attributes: {
        recruitment_target: 500,
        fee_per_declaration: 100,
      },
    }
  end

  before { allow(Events::Record).to receive(:record_contract_created_event!) }

  it "creates and returns a contract for the active lead provider, and records the created event" do
    active_lead_provider.reload
    
    contract = service.call

    expect(contract).to be_persisted
    expect(contract.active_lead_provider).to eq(active_lead_provider)
    expect(contract.banded_fee_structure).to have_attributes(recruitment_target: 1_000)
    expect(contract.banded_fee_structure.bands.size).to eq(3)
    
    expect(contract.banded_fee_structure.bands.first.fee_per_declaration).to eq 200
    expect(contract.banded_fee_structure.bands.second.fee_per_declaration).to eq 100
    expect(contract.banded_fee_structure.bands.third.fee_per_declaration).to eq 50       

    expect(contract.banded_fee_structure.bands.first.output_fee_percentage).to eq 75
    expect(contract.banded_fee_structure.bands.second.output_fee_percentage).to eq 75
    expect(contract.banded_fee_structure.bands.third.output_fee_percentage).to eq 50       
    
    expect(contract.banded_fee_structure.bands.first.service_fee_percentage).to eq 25
    expect(contract.banded_fee_structure.bands.second.service_fee_percentage).to eq 25
    expect(contract.banded_fee_structure.bands.third.service_fee_percentage).to eq 50 
    
    expect(contract.flat_rate_fee_structure).to have_attributes(recruitment_target: 500)
    expect(Events::Record).to have_received(:record_contract_created_event!).with(author:, contract:)
  end
end
