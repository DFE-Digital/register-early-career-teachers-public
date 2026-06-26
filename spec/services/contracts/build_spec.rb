describe Contracts::Build do
  subject(:service) { described_class.new(active_lead_provider:) }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

  describe "#call" do

    context "when no bands" do
      it { expect{ service.call }.to raise_error(StandardError) }
    end

    context "when active_lead_provider has bands" do
      subject(:contract) { service.call }
      let(:active_lead_provider_bands) { FactoryBot.create_list(:active_lead_provider_band, 3, active_lead_provider:) }
      before { active_lead_provider_bands }

      it "returns an unpersisted contract for the active lead provider" do
        expect(contract).not_to be_persisted
        expect(contract.active_lead_provider).to eq(active_lead_provider)
        expect(contract.flat_rate_fee_structure).to be_present
        expect(contract.banded_fee_structure.bands.size).to eq(3)
        contract.banded_fee_structure.bands.zip(active_lead_provider_bands).each do |band_term, band|
          expect(band_term.band).to eq(band)
        end
      end    
    end  
  end
end
