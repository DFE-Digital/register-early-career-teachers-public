RSpec.describe "Unfunded mentors API", type: :request do
  include MentorshipPeriodHelpers

  let(:serializer) { API::Teachers::UnfundedMentorSerializer }
  let(:serializer_options) { { lead_provider_id: lead_provider.id } }
  let(:query) { API::Teachers::UnfundedMentors::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)

    create_mentorship_period_for(
      mentee_school_partnership: school_partnership,
      refresh_metadata: true
    ).mentor.teacher
  end

  describe "#index" do
    let(:path) { api_v3_unfunded_mentors_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a filter by updated_since endpoint", updated_at_column: :api_unfunded_mentor_updated_at
    it_behaves_like "a sortable endpoint", updated_at_column: :api_unfunded_mentor_updated_at
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_unfunded_mentor_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by updated_since endpoint"
  end
end
