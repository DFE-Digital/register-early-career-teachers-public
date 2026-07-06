RSpec.describe "Admin finance active lead provider lead provider delivery partnerships", :enable_finance_contract_periods, type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }

  let(:index_path) { admin_contract_period_active_lead_provider_lead_provider_delivery_partnerships_path(contract_period, active_lead_provider) }
  let(:new_path) { new_admin_contract_period_active_lead_provider_lead_provider_delivery_partnership_path(contract_period, active_lead_provider) }
  let(:delete_path) { delete_admin_contract_period_active_lead_provider_lead_provider_delivery_partnership_path(contract_period, active_lead_provider, lead_provider_delivery_partnership) }
  let(:destroy_path) { admin_contract_period_active_lead_provider_lead_provider_delivery_partnership_path(contract_period, active_lead_provider, lead_provider_delivery_partnership) }

  describe "GET .../lead_provider_delivery_partnerships" do
    let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }

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

      it "renders the delivery partnerships index page" do
        get index_path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period is payments frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

        it "renders the delivery partnerships index page" do
          get index_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "GET .../lead_provider_delivery_partnerships/new" do
    it "redirects to sign in path when not signed in" do
      get new_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the new form" do
        get new_path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period is payments frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

        it "blocks the new form, redirecting to the index" do
          get new_path
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        get new_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST .../lead_provider_delivery_partnerships" do
    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "creates a delivery partnership and redirects to the index" do
        expect {
          post index_path, params: { lead_provider_delivery_partnership: { delivery_partner_id: delivery_partner.id } }
        }.to change(LeadProviderDeliveryPartnership, :count).by(1)

        expect(response).to redirect_to(index_path)
      end

      context "when the params are invalid" do
        it "re-renders with an error status" do
          post index_path, params: { lead_provider_delivery_partnership: { delivery_partner_id: nil } }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period is payments frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

        it "blocks the create, redirecting to the index" do
          expect {
            post index_path, params: { lead_provider_delivery_partnership: { delivery_partner_id: delivery_partner.id } }
          }.not_to change(LeadProviderDeliveryPartnership, :count)
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        post index_path, params: { lead_provider_delivery_partnership: { delivery_partner_id: delivery_partner.id } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET .../lead_provider_delivery_partnerships/:id/delete" do
    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the confirmation page" do
        get delete_path
        expect(response).to have_http_status(:ok)
      end

      context "when the delivery partner has school partnerships" do
        before do
          school = FactoryBot.create(:school)
          FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:)
        end

        it "renders the confirmation page" do
          get delete_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the contract period is payments frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

        it "blocks the delete page, redirecting to the index" do
          get delete_path
          expect(response).to redirect_to(index_path)
        end
      end
    end
  end

  describe "DELETE .../lead_provider_delivery_partnerships/:id" do
    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "destroys the delivery partnership and redirects to the index" do
        lead_provider_delivery_partnership

        expect {
          delete destroy_path
        }.to change(LeadProviderDeliveryPartnership, :count).by(-1)

        expect(response).to redirect_to(index_path)
      end

      context "when the delivery partner has school partnerships" do
        before do
          school = FactoryBot.create(:school)
          FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:)
        end

        it "does not destroy and redirects with an error" do
          expect {
            delete destroy_path
          }.not_to change(LeadProviderDeliveryPartnership, :count)

          expect(response).to redirect_to(index_path)
        end
      end

      context "when the contract period is payments frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

        it "blocks the destroy, redirecting to the index" do
          lead_provider_delivery_partnership

          expect {
            delete destroy_path
          }.not_to change(LeadProviderDeliveryPartnership, :count)
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        delete destroy_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
