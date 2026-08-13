describe Contracts::Create do
  subject(:service) { described_class.new(author:, framework_agreement:, params:) }

  let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
  let(:alp_band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  let(:params) do
    {
      contract_type: "ittecf_ectp",
      banded_fee_structure_attributes: {
        **banded_fee_structure_attributes,
        band_terms_attributes: [
          { **band_terms_attributes, band_id: alp_band.id },
        ],
      },
      flat_rate_fee_structure_attributes:,
    }
  end

  let(:flat_rate_fee_structure_attributes) do
    {
      recruitment_target: 500,
      fee_per_declaration: 100,
    }
  end

  let(:banded_fee_structure_attributes) do
    {
      recruitment_target: 1_000,
      uplift_fee_per_declaration: 50,
      monthly_service_fee: 5_000,
      setup_fee: 10_000
    }
  end

  let(:band_terms_attributes) do
    {
      fee_per_declaration: 200,
      output_fee_ratio: 0.75,
      service_fee_ratio: 0.25
    }
  end

  before { allow(Events::Record).to receive(:record_contract_created_event!) }

  context "when successful" do
    it "creates and returns a contract for the active lead provider, and records the created event" do
      contract = nil
      expect { contract = service.call }.to change(Contract, :count).by(1)

      expect(contract).to be_persisted
      expect(contract.framework_agreement).to eq(framework_agreement)
      expect(contract.banded_fee_structure).to have_attributes(banded_fee_structure_attributes)
      expect(contract.banded_fee_structure.bands.size).to eq(1)
      expect(contract.flat_rate_fee_structure).to have_attributes(flat_rate_fee_structure_attributes)
      expect(Events::Record).to have_received(:record_contract_created_event!).with(author:, contract:)
    end
  end

  context "when the active lead provider band is mismatched" do
    let(:alp_band) { FactoryBot.create(:framework_agreement_band) }

    it "does not create a contract or event" do
      expect { service.call }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Banded fee structure band terms band must belong to the contract's active lead provider")
      expect(Events::Record).not_to have_received(:record_contract_created_event!)
    end
  end
end
