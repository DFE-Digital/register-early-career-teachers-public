RSpec.describe "Admin delivery partners", type: :request do
  describe "GET /admin/organisations/delivery-partners" do
    let(:index_path) { admin_delivery_partners_path }

    it "redirects to sign in path" do
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

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      context "with search query" do
        let!(:matching_delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
        let!(:other_delivery_partner) { FactoryBot.create(:delivery_partner, name: "Other Partner") }

        it "filters delivery partners by name" do
          get index_path, params: {q: "Test Delivery"}

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
          get index_path, params: {q: "nonexistent"}

          expect(response.body).to include("There are no delivery partners that match your search.")
        end
      end
    end
  end

  describe "GET /admin/organisations/delivery-partners/:id" do
    let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test College Delivery Partner") }
    let(:show_path) { admin_delivery_partner_path(delivery_partner) }

    it "redirects to sign in path" do
      get show_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get show_path
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

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

      it "shows empty state when no contract periods with available lead providers exist" do
        get show_path

        expect(response.body).to include("No contract periods with available lead providers found")
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
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get new_path
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

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
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2026, enabled: false) }
    let(:create_path) { admin_delivery_partner_delivery_partnership_path(delivery_partner, contract_period.year) }
    let!(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
    let!(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
    let!(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
    let!(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

    it "redirects to sign in path" do
      post create_path, params: {lead_provider_ids: [active_lead_provider_1.id]}
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post create_path, params: {lead_provider_ids: [active_lead_provider_1.id]}
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      context "with valid parameters" do
        let(:lead_provider_ids) { [active_lead_provider_1.id, active_lead_provider_2.id] }

        it "updates lead provider partnerships" do
          expect {
            post create_path, params: {lead_provider_ids:}
          }.to change(LeadProviderDeliveryPartnership, :count).by(2)
        end

        it "redirects to show page with success message" do
          post create_path, params: {lead_provider_ids:}
          expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
          follow_redirect!
          expect(response.body).to include("Lead provider partners updated")
        end

        it "calls the update service" do
          service_double = instance_double(DeliveryPartners::UpdateLeadProviderPairings)
          allow(DeliveryPartners::UpdateLeadProviderPairings).to receive(:new).and_return(service_double)
          expect(service_double).to receive(:update!)

          post create_path, params: {lead_provider_ids:}
        end
      end

      context "with existing partnerships" do
        let!(:existing_partnership_1) do
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            delivery_partner:,
            active_lead_provider: active_lead_provider_1
          )
        end

        let!(:existing_partnership_2) do
          FactoryBot.create(
            :lead_provider_delivery_partnership,
            delivery_partner:,
            active_lead_provider: active_lead_provider_2
          )
        end

        context "when unchecking some partnerships" do
          let(:lead_provider_ids) { [active_lead_provider_1.id] }

          it "removes unchecked partnerships" do
            expect {
              post create_path, params: {lead_provider_ids:}
            }.to change(LeadProviderDeliveryPartnership, :count).by(-1)

            remaining_partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
            expect(remaining_partnerships.map(&:active_lead_provider_id)).to contain_exactly(active_lead_provider_1.id)
          end

          it "redirects with success message" do
            post create_path, params: {lead_provider_ids:}
            expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
            follow_redirect!
            expect(response.body).to include("Lead provider partners updated")
          end
        end

        context "when adding new partnerships while keeping existing ones" do
          let!(:lead_provider_3) { FactoryBot.create(:lead_provider, name: "Lead Provider 3") }
          let!(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_3, contract_period:) }
          let(:lead_provider_ids) { [active_lead_provider_1.id, active_lead_provider_2.id, active_lead_provider_3.id] }

          it "keeps existing partnerships and adds new ones" do
            expect {
              post create_path, params: {lead_provider_ids:}
            }.to change(LeadProviderDeliveryPartnership, :count).by(1)

            partnerships = delivery_partner.lead_provider_delivery_partnerships.reload
            expect(partnerships.map(&:active_lead_provider_id)).to contain_exactly(
              active_lead_provider_1.id,
              active_lead_provider_2.id,
              active_lead_provider_3.id
            )
          end
        end

        context "when checkbox persistence is tested" do
          let(:new_path) { new_admin_delivery_partner_delivery_partnership_path(delivery_partner, contract_period.year) }

          it "shows existing partnerships as checked when form is reopened" do
            # First, verify partnerships exist
            get new_path
            expect(response.status).to eq(200)

            # Check that existing partnerships are shown as checked
            expect(response.body).to include("checked")
            expect(response.body).to include("value=\"#{active_lead_provider_1.id}\"")
            expect(response.body).to include("value=\"#{active_lead_provider_2.id}\"")
          end

          it "persists checkbox state after form submission and reopening" do
            # Submit form with only one provider selected (removing the second one)
            post create_path, params: {lead_provider_ids: [active_lead_provider_1.id]}
            expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))

            # Verify the partnerships were updated correctly
            remaining_partnerships = delivery_partner.lead_provider_delivery_partnerships.for_contract_period(contract_period)
            expect(remaining_partnerships.count).to eq(1)
            expect(remaining_partnerships.first.active_lead_provider_id).to eq(active_lead_provider_1.id)

            # Reopen form and verify only the selected provider is checked
            get new_path
            expect(response.status).to eq(200)

            # Parse the response to check checkbox states
            doc = Nokogiri::HTML(response.body)
            checkbox_1 = doc.at_css("input[value='#{active_lead_provider_1.id}']")
            checkbox_2 = doc.at_css("input[value='#{active_lead_provider_2.id}']")

            # Verify checkbox states

            # Verify checkbox 1 is checked and checkbox 2 is not checked
            expect(checkbox_1).to be_present
            expect(checkbox_2).to be_present
            expect(checkbox_1["checked"]).to eq("checked")
            expect(checkbox_2["checked"]).to be_nil
          end
        end
      end

      context "with no lead providers selected" do
        context "for future contract periods" do
          it "allows empty selections and redirects with success message" do
            post create_path
            expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
            follow_redirect!
            expect(response.body).to include("Lead provider partners updated")
          end

          it "removes all existing partnerships" do
            # Create existing partnerships first
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              delivery_partner:,
              active_lead_provider: active_lead_provider_1
            )
            FactoryBot.create(
              :lead_provider_delivery_partnership,
              delivery_partner:,
              active_lead_provider: active_lead_provider_2
            )

            expect {
              post create_path
            }.to change(LeadProviderDeliveryPartnership, :count).by(-2)
          end
        end

        context "for current contract periods" do
          let(:contract_period) { FactoryBot.create(:contract_period, year: 2025, enabled: true, started_on: 1.year.ago, finished_on: 1.month.from_now) }

          it "redirects back to new page with error message" do
            post create_path
            expect(response).to redirect_to(new_admin_delivery_partner_delivery_partnership_path(delivery_partner, contract_period.year))
            follow_redirect!
            expect(response.body).to include("Select at least one lead provider")
          end

          it "does not create or remove partnerships" do
            expect {
              post create_path
            }.not_to change(LeadProviderDeliveryPartnership, :count)
          end
        end
      end

      context "with invalid contract period" do
        let(:invalid_create_path) { admin_delivery_partner_delivery_partnership_path(delivery_partner, 9999) }

        it "redirects with error message" do
          post invalid_create_path, params: {lead_provider_ids: [active_lead_provider_1.id]}
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
          post create_path, params: {lead_provider_ids:}
          expect(response).to redirect_to(admin_delivery_partner_path(delivery_partner))
          follow_redirect!
          expect(response.body).to include("Unable to update lead provider partners")
        end
      end
    end
  end
end
