RSpec.describe "Admin active lead providers", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:index_path) { admin_contract_period_active_lead_providers_path(contract_period) }
  let(:started_error) { "Active lead providers cannot be changed once the contract period has started" }

  describe "GET /admin/contract-periods/:contract_period_id/active-lead-providers" do
    it "redirects to sign in path when not signed in" do
      get index_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get index_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the active lead providers index page" do
        get index_path
        expect(response.status).to eq(200)
      end
    end
  end

  describe "GET /admin/contract-periods/:contract_period_id/active-lead-providers/new" do
    let(:new_path) { new_admin_contract_period_active_lead_provider_path(contract_period) }

    it "redirects to sign in path when not signed in" do
      get new_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get new_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the new active lead provider page" do
        get new_path
        expect(response.status).to eq(200)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "redirects to the index with an alert" do
          get new_path
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq(started_error)
        end
      end
    end
  end

  describe "POST /admin/contract-periods/:contract_period_id/active-lead-providers" do
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:params) { { active_lead_provider: { lead_provider_id: lead_provider.id } } }

    it "redirects to sign in path when not signed in" do
      post(index_path, params:)
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post(index_path, params:)
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      let(:previous_contract_period) { FactoryBot.create(:contract_period, :current) }
      let(:previous_activation) { FactoryBot.create(:active_lead_provider, contract_period: previous_contract_period, lead_provider:) }
      let(:previous_contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: previous_activation) }
      let!(:previous_delivery_partnerships) do
        FactoryBot.create_list(:lead_provider_delivery_partnership, 2, active_lead_provider: previous_activation)
      end

      let!(:previous_statement) do
        FactoryBot.create(:statement, :paid, active_lead_provider: previous_activation, contract: previous_contract, month: 11, year: previous_contract_period.year)
      end

      it "creates an active lead provider seeded from the previous period, and redirects to the index" do
        expect { post index_path, params: }.to change(ActiveLeadProvider, :count).by(1)

        active_lead_provider = ActiveLeadProvider.last
        expect(active_lead_provider).to have_attributes(contract_period_year: contract_period.year, lead_provider_id: lead_provider.id)
        expect(active_lead_provider.lead_provider_delivery_partnerships.map(&:delivery_partner))
          .to match_array(previous_activation.lead_provider_delivery_partnerships.map(&:delivery_partner))
        expect(active_lead_provider.contracts.size).to eq(1)
        expect(active_lead_provider.contracts.first.statements.map { |s| [s.month, s.year] })
          .to contain_exactly([11, contract_period.year])
        expect(response).to redirect_to(admin_contract_period_active_lead_providers_path(contract_period))
      end

      context "when the lead provider is missing" do
        let(:params) { { active_lead_provider: { lead_provider_id: "" } } }

        it "does not create an active lead provider and re-renders new" do
          expect { post index_path, params: }.not_to(change(ActiveLeadProvider, :count))

          expect(response.status).to eq(422)
        end
      end

      context "when the lead provider already has an active lead provider for the contract period" do
        before { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }

        it "does not create a duplicate and re-renders new" do
          expect { post index_path, params: }.not_to(change(ActiveLeadProvider, :count))

          expect(response.status).to eq(422)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "does not create an active lead provider and redirects to the index with an alert" do
          expect { post index_path, params: }.not_to(change(ActiveLeadProvider, :count))

          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq(started_error)
        end
      end
    end
  end

  describe "DELETE /admin/contract-periods/:contract_period_id/active-lead-providers/:id" do
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
    let(:destroy_path) { admin_contract_period_active_lead_provider_path(contract_period, active_lead_provider) }

    it "redirects to sign in path when not signed in" do
      delete destroy_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        delete destroy_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "destroys the active lead provider and redirects to the index" do
        expect { delete destroy_path }.to change(ActiveLeadProvider, :count).by(-1)

        expect(response).to redirect_to(admin_contract_period_active_lead_providers_path(contract_period))
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "does not destroy the active lead provider and redirects to the index with an alert" do
          expect { delete destroy_path }.not_to(change(ActiveLeadProvider, :count))

          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq(started_error)
        end
      end
    end
  end
end
