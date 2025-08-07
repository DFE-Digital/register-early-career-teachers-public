RSpec.describe "Admin delivery partners", type: :request do
  describe "GET /admin/organisations/delivery-partners" do
    let(:index_path) { admin_delivery_partners_path }

    it "redirects to sign in path" do
      get index_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get index_path
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      context "with search query" do
        let!(:matching_delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
        let!(:other_delivery_partner) { FactoryBot.create(:delivery_partner, name: "Other Partner") }

        it "filters delivery partners by name" do
          get index_path, params: { q: "Test Delivery" }

          expect(response.status).to eq(200)
          expect(response.body).to include("Test Delivery Partner")
          expect(response.body).not_to include("Other Partner")
        end
      end

      context "when delivery partners exist" do
        let!(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Partner") }

        it "displays delivery partners" do
          get index_path

          expect(response.body).to include("Test Partner")
        end
      end

      context "when no delivery partners exist" do
        it "shows empty state" do
          get index_path

          expect(response.body).to include("No delivery partners found.")
        end

        it "shows search empty state" do
          get index_path, params: { q: "nonexistent" }

          expect(response.body).to include("There are no delivery partners that match your search.")
        end
      end
    end
  end

  describe "GET /admin/organisations/delivery-partners/:id" do
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:show_path) { admin_delivery_partner_path(delivery_partner) }

    it "redirects to sign in path" do
      get show_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get show_path
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it "returns http success" do
        get show_path
        expect(response).to have_http_status(:success)
      end

      it "displays delivery partner name" do
        get show_path

        expect(response.body).to include(delivery_partner.name)
      end

      context "with partnerships" do
        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
        let!(:partnership) do
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            delivery_partner:,
            active_lead_provider:
          )
        end

        it "displays lead provider partnerships" do
          get show_path

          expect(response.body).to include(partnership.lead_provider.name)
          expect(response.body).to include(partnership.contract_period.year.to_s)
        end
      end

      it "shows empty state when no partnerships exist" do
        get show_path

        expect(response.body).to include("No lead provider partnerships found")
      end

      context "with multiple partnerships for ordering" do
        let(:old_contract_period) { FactoryBot.create(:contract_period, year: 2021) }
        let(:new_contract_period) { FactoryBot.create(:contract_period, year: 2023) }
        let(:old_lead_provider) { FactoryBot.create(:lead_provider) }
        let(:new_lead_provider) { FactoryBot.create(:lead_provider) }
        let(:old_active_lead_provider) do
          FactoryBot.create(:active_lead_provider, contract_period: old_contract_period, lead_provider: old_lead_provider)
        end
        let(:new_active_lead_provider) do
          FactoryBot.create(:active_lead_provider, contract_period: new_contract_period, lead_provider: new_lead_provider)
        end

        let!(:old_partnership) do
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            delivery_partner:,
            active_lead_provider: old_active_lead_provider
          )
        end
        let!(:new_partnership) do
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            delivery_partner:,
            active_lead_provider: new_active_lead_provider
          )
        end

        it "orders partnerships by most recent year first" do
          get show_path

          # Check that 2023 appears before 2021 in the response
          expect(response.body.index("2023")).to be < response.body.index("2021")
        end
      end
    end
  end

  describe "GET /admin/organisations/delivery-partners/:delivery_partner_id/:year/new" do
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
    let(:new_path) { new_admin_delivery_partner_delivery_partnership_path(delivery_partner, contract_period.year) }

    it "redirects to sign in path" do
      get new_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get new_path
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      context "with valid contract period" do
        let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
        let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
        let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
        let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

        it "returns http success" do
          get new_path
          expect(response).to have_http_status(:success)
        end

        it "displays the page title" do
          get new_path
          expect(response.body).to include("Select lead providers working with #{delivery_partner.name} in #{contract_period.year}")
        end

        it "displays available lead providers as checkboxes" do
          get new_path
          expect(response.body).to include(lead_provider_1.name)
          expect(response.body).to include(lead_provider_2.name)
        end

        context "with existing partnerships" do
          let!(:existing_partnership) do
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              delivery_partner:,
              active_lead_provider: active_lead_provider_1
            )
          end

          it "shows currently associated lead providers" do
            get new_path
            expect(response.body).to include("Currently working with:")
            expect(response.body).to include(lead_provider_1.name)
          end

          it "excludes already assigned lead providers from checkboxes" do
            get new_path
            expect(response.body).not_to include("value=\"#{active_lead_provider_1.id}\"")
            expect(response.body).to include("value=\"#{active_lead_provider_2.id}\"")
          end
        end
      end

      context "with invalid contract period" do
        let(:invalid_new_path) { new_admin_delivery_partner_delivery_partnership_path(delivery_partner, 9999) }

        it "redirects with error message" do
          get invalid_new_path
          expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
          follow_redirect!
          expect(response.body).to include("Contract period for year 9999 not found")
        end
      end
    end
  end

  describe "POST /admin/organisations/delivery-partners/:delivery_partner_id/:year" do
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
    let(:create_path) { admin_delivery_partner_delivery_partnership_path(delivery_partner, contract_period.year) }
    let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
    let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
    let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
    let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

    it "redirects to sign in path" do
      post create_path, params: { lead_provider_ids: [active_lead_provider_1.id] }
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        post create_path, params: { lead_provider_ids: [active_lead_provider_1.id] }
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      context "with valid parameters" do
        let(:lead_provider_ids) { [active_lead_provider_1.id, active_lead_provider_2.id] }

        it "updates lead provider partnerships" do
          expect {
            post create_path, params: { lead_provider_ids: }
          }.to change(LeadProviderDeliveryPartnership, :count).by(2)
        end

        it "redirects to show page with success message" do
          post create_path, params: { lead_provider_ids: }
          expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
          follow_redirect!
          expect(response.body).to include("Lead provider partners updated")
        end

        it "calls the update service" do
          service_double = instance_double(DeliveryPartners::UpdateLeadProviderPairings)
          allow(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).and_return(service_double)
          expect(service_double).to receive(:update!)

          post create_path, params: { lead_provider_ids: }
        end
      end

      context "with no lead providers selected" do
        it "redirects back to new page with error message" do
          post create_path
          expect(response).to redirect_to(new_admin_delivery_partner_delivery_partnership_path(delivery_partner, contract_period.year))
          follow_redirect!
          expect(response.body).to include("Select at least one lead provider")
        end

        it "does not create partnerships" do
          expect {
            post create_path
          }.not_to change(LeadProviderDeliveryPartnership, :count)
        end
      end

      context "with invalid contract period" do
        let(:invalid_create_path) { admin_delivery_partner_delivery_partnership_path(delivery_partner, 9999) }

        it "redirects with error message" do
          post invalid_create_path, params: { lead_provider_ids: [active_lead_provider_1.id] }
          expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
          follow_redirect!
          expect(response.body).to include("Contract period for year 9999 not found")
        end
      end

      context "when service fails" do
        let(:lead_provider_ids) { [active_lead_provider_1.id] }

        before do
          service_double = instance_double(DeliveryPartners::UpdateLeadProviderPairings)
          allow(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:update!).and_return(false)
        end

        it "redirects with error message" do
          post create_path, params: { lead_provider_ids: }
          expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
          follow_redirect!
          expect(response.body).to include("Unable to update lead provider partners")
        end
      end
    end
  end
end
