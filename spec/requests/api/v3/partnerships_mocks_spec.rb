RSpec.describe "Partnerships APIs (mocking)", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Partnerships::Query }
  let(:query_method) { :partnerships }
  let(:serializer) { API::PartnershipSerializer }
  let(:response_type) { SchoolPartnership }

  describe "GET /api/v3/partnerships/:id" do
    let(:path) { api_v3_partnerships_path }

    it_behaves_like "an API index endpoint (mocking)"
  end

  describe "POST /api/v3/partnerships" do
    let(:path) { api_v3_partnerships_path }
    let(:service) { API::SchoolPartnerships::Create }
    let(:action) { :create }
    let(:resource) { create(:school_partnership) }

    let(:lead_provider_active_period) { create(:lead_provider_active_period, lead_provider: current_lead_provider) }
    let(:lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, lead_provider_active_period:) }
    let(:gias_school) { create(:gias_school, :eligible_for_fip, :eligible_type) }
    let(:school) { create(:school, urn: gias_school.urn, gias_school: nil) }
    let(:ect_at_school_period) { create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 1.week.ago) }
    let!(:fip_participant) { create(:training_period, ect_at_school_period:, started_on: 2.months.ago, finished_on: 1.month.ago) }
    let(:attributes) do
      {
        cohort: lead_provider_active_period.registration_period.year,
        school_id: school.ecf_id,
        delivery_partner_id: lead_provider_delivery_partnership.delivery_partner.ecf_id,
      }
    end
    let(:service_args) do
      {
        registration_year: attributes[:cohort],
        school_ecf_id: attributes[:school_id],
        delivery_partner_ecf_id: attributes[:delivery_partner_id],
        lead_provider_ecf_id: current_lead_provider.ecf_id,
      }
    end

    it_behaves_like "an API create endpoint (mocking)"
  end
end
