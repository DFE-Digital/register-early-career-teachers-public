RSpec.describe "Partnerships APIs", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:serializer) { API::PartnershipSerializer }

  describe "GET /api/v3/partnerships/:id" do
    let(:path) { api_v3_partnerships_path }

    def create_resource(**attrs)
      lead_provider_active_period = create(:lead_provider_active_period, **attrs)
      lead_provider_delivery_partnership = create(:lead_provider_delivery_partnership, lead_provider_active_period:)
      create(:school_partnership, lead_provider_delivery_partnership:)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
  end

  describe "POST /api/v3/partnerships" do
    let(:path) { api_v3_partnerships_path }
    let(:resource_type) { SchoolPartnership }
    let(:attributes) do
      {
        cohort: lead_provider_delivery_partnership.registration_period.year,
        school_id: school.ecf_id,
        delivery_partner_id: lead_provider_delivery_partnership.delivery_partner.ecf_id,
      }
    end

    let(:current_lead_provider) { lead_provider_delivery_partnership.lead_provider }
    let(:lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership) }
    let(:school) { create(:school, urn: 123, gias_school: create(:gias_school, :eligible_for_fip, :eligible_type, urn: 123)) }
    let(:ect_at_school_period) { create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 1.week.ago) }
    let!(:fip_participant) { create(:training_period, ect_at_school_period:, started_on: 2.months.ago, finished_on: 1.month.ago) }

    it_behaves_like "an API create endpoint" do
      def assert_on_created_resource(school_partnership)
        expect(school_partnership).to have_attributes(
          lead_provider_delivery_partnership:,
          school:
        )
      end
    end
  end
end
