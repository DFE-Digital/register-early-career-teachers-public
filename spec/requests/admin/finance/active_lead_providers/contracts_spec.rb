RSpec.describe "Admin finance active lead provider contracts", :enable_finance_contract_periods, type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

  let(:path) { admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider) }

  describe "GET .../contracts" do
    it "redirects to sign in path when not signed in" do
      get path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "returns success" do
        get path
        expect(response.status).to eq(200)
      end
    end
  end
end
