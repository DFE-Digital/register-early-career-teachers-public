RSpec.describe "Schools API", :with_metadata, type: :request do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }
  let(:contract_period) { active_lead_provider.contract_period }
  let(:serializer) { API::SchoolSerializer }
  let(:serializer_options) { { contract_period_year: contract_period.id, lead_provider_id: lead_provider.id } }

  def create_resource(active_lead_provider:)
    # Set up a school with a provider-led training programme linked to the given active lead provider
    # And a training period within an ongoing ECT at school period so all fields are populated
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    school = FactoryBot.create(:school, :ineligible, :with_induction_tutor)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:)
    ect_at_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, school:)
    FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period:, school_partnership:)
    school
  end

  describe "#index" do
    let(:path) { api_v3_schools_path(filter: { cohort: contract_period.id }) }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a sortable endpoint" do
      def set_updated_at(resource:, value:)
        resource.contract_period_metadata.update_all(api_updated_at: value)
      end

      def sort_resources(resources, sort_attribute)
        return resources.sort_by!(&:"#{sort_attribute}") unless /updated_at/.match?(sort_attribute)

        resources.sort_by! { it.contract_period_metadata.map(&:"#{sort_attribute}") }
      end
    end
    it_behaves_like "a filter by a single cohort (contract_period year) endpoint"
    it_behaves_like "a filter by updated_since endpoint" do
      def set_updated_at(resource:, value:)
        resource.contract_period_metadata.update_all(api_updated_at: value)
      end
    end
    it_behaves_like "a filter validatable endpoint", %i[cohort]
    it_behaves_like "a filter by urn endpoint"
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_school_path(path_id, filter: { cohort: contract_period.id }) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by updated_since endpoint" do
      def get_updated_at(resource:)
        resource.contract_period_metadata.map(&:api_updated_at).max
      end
    end
  end
end
