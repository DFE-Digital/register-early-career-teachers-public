RSpec.describe "Admin finance active lead provider statements", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let!(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }
  let(:path) { admin_active_lead_provider_statements_path(active_lead_provider) }

  describe "GET /admin/finance/active-lead-providers/:active_lead_provider_id/statements" do
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

      it "displays the active lead provider's statements" do
        get path

        expect(response.status).to eq(200)
        expect(response.body).to include("Lead Provider 1")
        expect(response.body).to include(Statements::Period.for(statement))
      end
    end
  end
end
