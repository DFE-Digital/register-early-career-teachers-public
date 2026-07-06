RSpec.describe "Admin finance active lead provider bands", :enable_finance_contract_periods, type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }

  describe "GET .../bands" do
    let(:path) { admin_contract_period_active_lead_provider_bands_path(contract_period, active_lead_provider) }

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

  describe "GET .../bands/new" do
    let(:path) { new_admin_contract_period_active_lead_provider_band_path(contract_period, active_lead_provider) }

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

  describe "POST .../bands" do
    let(:index_path) { admin_contract_period_active_lead_provider_bands_path(contract_period, active_lead_provider) }

    it "redirects to sign in path when not signed in" do
      post index_path, params: { active_lead_provider_band: { capacity: 500 } }
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post index_path, params: { active_lead_provider_band: { capacity: 500 } }
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      let(:contract_period) { FactoryBot.create(:contract_period, :next) }

      it "creates a new band and redirects to the index" do
        expect {
          post index_path, params: { active_lead_provider_band: { capacity: 500 } }
        }.to change(ActiveLeadProvider::Band, :count).by(1)

        expect(response).to redirect_to(index_path)
        expect(flash[:notice]).to eq "Band A added"
      end

      context "when the params are invalid" do
        it "re-renders with an error status" do
          post index_path, params: { active_lead_provider_band: { capacity: "eggs" } }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the create, redirecting to the index" do
          expect {
            post index_path, params: { active_lead_provider_band: { capacity: 500 } }
          }.not_to change(ActiveLeadProvider::Band, :count)
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq "Bands cannot be added or removed once contracts have been added or the contract period has started"
        end
      end
    end
  end
end
