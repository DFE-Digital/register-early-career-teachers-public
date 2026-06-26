RSpec.describe "Admin finance active lead provider contracts", :enable_finance_contract_periods, type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }

  describe "GET .../contracts" do
    let(:path) { admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider) }

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

  describe "GET .../contracts/:id" do
    let(:path) { admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract) }

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

  describe "GET .../contracts/new" do
    let(:path) { new_admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider) }
    let!(:bands) { FactoryBot.create_list(:active_lead_provider_band, 3, active_lead_provider:) }

    it "redirects to sign in path when not signed in" do
      get path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the new contract form" do
        get path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the new form, redirecting to the contracts index" do
          get path
          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
        end
      end
    end
  end

  describe "POST .../contracts" do
    let(:path) { admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider) }
    let!(:bands) { FactoryBot.create_list(:active_lead_provider_band, 3, active_lead_provider: active_lead_provider) }

    let(:valid_params) do
      {
        contract: {
          contract_type: "ittecf_ectp",
          ecf_contract_version: "1",
          ecf_mentor_contract_version: "2",
          banded_fee_structure_attributes: {
            recruitment_target: 1_000,
            uplift_fee_per_declaration: 50,
            monthly_service_fee: 5_000,
            setup_fee: 10_000,
            bands_attributes: {
              "0" => { band_id: bands.first.id, fee_per_declaration: 200, output_fee_percentage: 75, service_fee_percentage: 25 },
              "1" => { band_id: bands.second.id, fee_per_declaration: 100, output_fee_percentage: 75, service_fee_percentage: 25 },
              "2" => { band_id: bands.third.id, fee_per_declaration: 50, output_fee_percentage: 50, service_fee_percentage: 50 }
            }
          },
          flat_rate_fee_structure_attributes: {
            recruitment_target: 500,
            fee_per_declaration: 100
          }
        }
      }
    end

    it "redirects to sign in path when not signed in" do
      post path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post path, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "creates a contract and redirects to the contract" do
        expect {
          post path, params: valid_params
        }.to change(Contract, :count).by(1)

        created_contract = Contract.last
        banded = created_contract.banded_fee_structure
        expect(banded).to have_attributes(recruitment_target: 1_000)
        expect(banded.bands.reload.map(&:fee_per_declaration)).to eq([200, 100, 50])
        expect(banded.bands.map(&:output_fee_percentage)).to eq([75, 75, 50])
        expect(banded.bands.map(&:service_fee_percentage)).to eq([25, 25, 50])
        expect(created_contract.flat_rate_fee_structure).to have_attributes(recruitment_target: 500)

        expect(response).to redirect_to(
          admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, created_contract)
        )
      end

      context "when the params are invalid" do
        it "re-renders the new form with an error status" do
          post path, params: { contract: { contract_type: "" } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the create, redirecting to the contracts index" do
          expect {
            post path, params: valid_params
          }.not_to change(Contract, :count)

          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
        end
      end
    end
  end

  describe "GET .../contracts/:id/edit" do
    let(:path) { edit_admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract) }

    it "redirects to sign in path when not signed in" do
      get path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the edit form" do
        get path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the edit form, redirecting to the contracts index" do
          get path
          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
        end
      end
    end
  end

  describe "PATCH .../contracts/:id" do
    let(:path) { admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract) }
    let!(:bands) { FactoryBot.create_list(:active_lead_provider_band, 3, active_lead_provider:) }

    let(:valid_params) do
      {
        contract: {
          ecf_contract_version: "updated-version",
          banded_fee_structure_attributes: {
            id: contract.banded_fee_structure.id,
            recruitment_target: 9_999,
            bands_attributes: {
              "0" => { band_id: bands.first.id, fee_per_declaration: 200, output_fee_percentage: 75, service_fee_percentage: 25 },
              "1" => { band_id: bands.second.id, fee_per_declaration: 100, output_fee_percentage: 75, service_fee_percentage: 25 },
              "2" => { band_id: bands.third.id, fee_per_declaration: 50, output_fee_percentage: 50, service_fee_percentage: 50 }
            }
          }
        }
      }
    end

    it "redirects to sign in path when not signed in" do
      patch path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        patch path, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "updates the contract and redirects to the contract" do
        patch path, params: valid_params

        contract.reload
        banded = contract.banded_fee_structure.reload
        expect(contract.ecf_contract_version).to eq("updated-version")
        expect(banded).to have_attributes(recruitment_target: 9_999)
        expect(Contract::BandedFeeStructure::Band.count).to eq(3)
        expect(banded.bands.reload.map(&:fee_per_declaration)).to eq([200, 100, 50])
        expect(banded.bands.map(&:output_fee_percentage)).to eq([75, 75, 50])
        expect(banded.bands.map(&:service_fee_percentage)).to eq([25, 25, 50])

        expect(response).to redirect_to(admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract))
      end

      context "when the params are invalid" do
        it "re-renders the edit form with an error status" do
          patch path, params: { contract: { ecf_contract_version: "" } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the update, redirecting to the contracts index" do
          patch path, params: valid_params
          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
        end
      end
    end
  end

  describe "GET .../contracts/:id/delete" do
    let(:path) { delete_admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract) }

    it "redirects to sign in path when not signed in" do
      get path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the delete confirmation page" do
        get path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the delete page, redirecting to the contracts index" do
          get path
          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
        end
      end
    end
  end

  describe "DELETE .../contracts/:id" do
    let(:path) { admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract) }

    it "redirects to sign in path when not signed in" do
      delete path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        delete path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "destroys the contract and redirects to the contracts index" do
        contract

        expect {
          delete path
        }.to change(Contract, :count).by(-1)

        expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
      end

      context "when the contract has statements" do
        before { FactoryBot.create(:statement, contract:, active_lead_provider:) }

        it "does not destroy the contract and redirects with an error" do
          expect {
            delete path
          }.not_to change(Contract, :count)

          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract))
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the destroy, redirecting to the contracts index" do
          contract

          expect {
            delete path
          }.not_to change(Contract, :count)

          expect(response).to redirect_to(admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))
        end
      end
    end
  end
end
