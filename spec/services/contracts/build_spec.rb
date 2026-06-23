describe Contracts::Build do
  subject(:service) { described_class.new(active_lead_provider:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

  describe "#call" do
    subject(:contract) { service.call }

    it "returns an unpersisted contract for the active lead provider" do
      expect(contract).not_to be_persisted
      expect(contract.active_lead_provider).to eq(active_lead_provider)
    end

    it "builds a flat_rate_fee_structure" do
      expect(contract.flat_rate_fee_structure).to be_present
    end

    context "when the active lead provider has no existing contracts with bands" do
      it "builds a single empty band" do
        expect(contract.banded_fee_structure.bands.size).to eq(1)
      end
    end

    context "when the active lead provider has an existing contract with bands" do
      let!(:existing_contract) { FactoryBot.create(:contract, active_lead_provider:) }

      it "seeds bands from the existing contract's band structure" do
        existing_bands = existing_contract.banded_fee_structure.bands
        built_bands = contract.banded_fee_structure.bands

        expect(built_bands.size).to eq(existing_bands.size)

        existing_bands.each_with_index do |existing_band, i|
          expect(built_bands[i]).to have_attributes(
            min_declarations: existing_band.min_declarations,
            max_declarations: existing_band.max_declarations,
            fee_per_declaration: existing_band.fee_per_declaration,
            output_fee_ratio: existing_band.output_fee_ratio,
            service_fee_ratio: existing_band.service_fee_ratio
          )
        end
      end
    end
  end
end
