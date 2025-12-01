RSpec.describe "Participant transfers API", type: :request do
  include SchoolTransferHelpers

  let(:serializer) { API::Teachers::SchoolTransferSerializer }
  let(:serializer_options) { { lead_provider_id: lead_provider.id } }
  let(:query) { API::Teachers::SchoolTransfers::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:)
    teacher = FactoryBot.create(:teacher)
    build_new_school_transfer(
      teacher:,
      lead_provider: active_lead_provider.lead_provider
    )
    teacher.tap { Metadata::Handlers::Teacher.new(it).refresh_metadata! }
  end

  describe "#index" do
    let(:path) { api_v3_transfers_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a filter by updated_since endpoint", updated_at_column: :api_updated_at
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { transfers_api_v3_participant_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by updated_since endpoint"
  end
end
