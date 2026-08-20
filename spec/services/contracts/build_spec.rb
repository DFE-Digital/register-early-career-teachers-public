describe Contracts::Build do
  subject(:service) { described_class.new(framework_agreement:) }

  let(:framework_agreement) { FactoryBot.create(:framework_agreement) }

  describe "#call" do
    subject(:contract) { service.call }

    it "returns an unpersisted contract for the framework agreement" do
      expect(contract).not_to be_persisted
      expect(contract.framework_agreement).to eq(framework_agreement)
    end

    it "builds a flat_rate_fee_structure" do
      expect(contract.flat_rate_fee_structure).to be_present
    end

    context "when the framework agreement has no bands" do
      it "builds no band terms" do
        expect(contract.banded_fee_structure.band_terms).to be_empty
      end
    end

    context "when the framework agreement has bands" do
      let!(:alp_band) do
        FactoryBot.create_list(:framework_agreement_band, 5,
                               framework_agreement:)
      end

      it "builds one band term per ALP band" do
        expect(contract.banded_fee_structure.band_terms.size).to eq(5)
      end
    end

    context "when the framework agreement has bands and a previous contract" do
      let!(:existing_contract) do
        FactoryBot.create(:contract, :for_ecf,
                          :with_bands_and_band_terms,
                          framework_agreement:)
      end

      it "seeds band terms from the existing contract's band structure" do
        existing_band_terms = existing_contract.banded_fee_structure.band_terms
        built_band_terms = contract.banded_fee_structure.band_terms

        expect(built_band_terms.size).to eq(existing_band_terms.size)

        existing_band_terms.each_with_index do |existing_band_term, i|
          expect(built_band_terms[i]).to have_attributes(
            fee_per_declaration: existing_band_term.fee_per_declaration,
            output_fee_ratio: existing_band_term.output_fee_ratio,
            service_fee_ratio: existing_band_term.service_fee_ratio
          )
        end
      end
    end
  end
end
