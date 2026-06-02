RSpec.describe Admin::ContractsHelper, type: :helper do
  describe "#contract_heading" do
    let(:contract) { FactoryBot.create(:contract) }

    it { expect(helper.contract_heading(contract)).to eq("ITTECF ECTP (20% VAT)") }

    context "when ECF type" do
      let(:contract) { FactoryBot.create(:contract, :for_ecf) }

      it { expect(helper.contract_heading(contract)).to eq("ECF (20% VAT)") }
    end

    context "when not VAT registered" do
      let(:lead_provider) { FactoryBot.create(:lead_provider, vat_registered: false) }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
      let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }

      it { expect(helper.contract_heading(contract)).to eq("ECF (0% VAT)") }
    end
  end
end
