RSpec.describe "Admin::Schools::AddPartnershipWizardController", type: :request do
  include_context "sign in as DfE user"

  let(:school) { FactoryBot.create(:school) }
  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:other_contract_period) { FactoryBot.create(:contract_period) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:other_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) do
    FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
  end
  let(:other_active_lead_provider) do
    FactoryBot.create(
      :active_lead_provider,
      contract_period: other_contract_period,
      lead_provider: other_lead_provider
    )
  end
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
  let!(:lead_provider_delivery_partnership) do
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
  end
  let!(:other_lead_provider_delivery_partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: other_active_lead_provider,
      delivery_partner: other_delivery_partner
    )
  end

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :with_only_expression_of_interest,
      ect_at_school_period:,
      expression_of_interest: active_lead_provider,
      schedule: FactoryBot.create(:schedule, contract_period:)
    )
  end

  describe "journey" do
    it "creates a partnership and links training periods" do
      get path_for_step("select-contract-period")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(contract_period.year.to_s)

      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: contract_period.year } }
      )

      expect(response).to redirect_to(path_for_step("select-lead-provider"))

      follow_redirect!
      expect(response.body).to include(lead_provider.name)
      expect(response.body).not_to include(other_lead_provider.name)

      post(
        path_for_step("select-lead-provider"),
        params: { select_lead_provider: { active_lead_provider_id: active_lead_provider.id } }
      )

      expect(response).to redirect_to(path_for_step("select-delivery-partner"))

      follow_redirect!
      expect(response.body).to include(delivery_partner.name)
      expect(response.body).not_to include(other_delivery_partner.name)

      post(
        path_for_step("select-delivery-partner"),
        params: { select_delivery_partner: { delivery_partner_id: delivery_partner.id } }
      )

      expect(response).to redirect_to(path_for_step("check-answers"))

      follow_redirect!
      expect(response.body).to include("Add partnership")
      expect(response.body).to include(school.name)
      expect(response.body).to include(contract_period.year.to_s)
      expect(response.body).to include(lead_provider.name)
      expect(response.body).to include(delivery_partner.name)

      expect {
        post path_for_step("check-answers"), params: { check_answers: {} }
      }.to change(SchoolPartnership, :count).by(1)

      expect(response).to redirect_to(admin_school_partnerships_path(school.urn))

      follow_redirect!
      expect(response.body).to include("Partnership added")

      training_period.reload
      expect(training_period.school_partnership).to be_present
      expect(training_period.school_partnership.lead_provider_delivery_partnership).to eq(lead_provider_delivery_partnership)
    end
  end

  describe "validation" do
    it "requires selections on each step" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: "" } }
      )
      expect(response.body).to include("Select a contract period")

      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: contract_period.year } }
      )
      follow_redirect!

      post(
        path_for_step("select-lead-provider"),
        params: { select_lead_provider: { active_lead_provider_id: "" } }
      )
      expect(response.body).to include("Select a lead provider")

      post(
        path_for_step("select-lead-provider"),
        params: { select_lead_provider: { active_lead_provider_id: active_lead_provider.id } }
      )
      follow_redirect!

      post(
        path_for_step("select-delivery-partner"),
        params: { select_delivery_partner: { delivery_partner_id: "" } }
      )
      expect(response.body).to include("Select a delivery partner")
    end

    it "shows an error when the partnership already exists" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: contract_period.year } }
      )
      follow_redirect!

      post(
        path_for_step("select-lead-provider"),
        params: { select_lead_provider: { active_lead_provider_id: active_lead_provider.id } }
      )
      follow_redirect!

      post(
        path_for_step("select-delivery-partner"),
        params: { select_delivery_partner: { delivery_partner_id: delivery_partner.id } }
      )
      follow_redirect!

      post path_for_step("check-answers"), params: { check_answers: {} }

      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: contract_period.year } }
      )
      follow_redirect!

      post(
        path_for_step("select-lead-provider"),
        params: { select_lead_provider: { active_lead_provider_id: active_lead_provider.id } }
      )
      follow_redirect!

      post(
        path_for_step("select-delivery-partner"),
        params: { select_delivery_partner: { delivery_partner_id: delivery_partner.id } }
      )
      follow_redirect!

      expect {
        post path_for_step("check-answers"), params: { check_answers: {} }
      }.not_to change(SchoolPartnership, :count)

      expect(response.body).to include("Partnership already exists for this school")
    end
  end

private

  def path_for_step(step)
    "/admin/schools/#{school.urn}/partnerships/add/#{step}"
  end
end
