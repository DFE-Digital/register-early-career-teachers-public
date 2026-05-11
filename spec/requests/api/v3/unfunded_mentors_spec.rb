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

    other_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider: FactoryBot.create(:lead_provider),
      contract_period_year: active_lead_provider.contract_period_year
    )
    other_lead_provider_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: other_active_lead_provider
    )

    mentor_school_partnership = SchoolPartnership.find_or_create_by!(
      school: school_partnership.school,
      lead_provider_delivery_partnership: other_lead_provider_delivery_partnership
    )

    # Unfunded mentor associated with the lead provider (should be returned)
    create_mentorship_period_for(
      mentee_school_partnership: school_partnership,
      mentor_school_partnership:,
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
    it_behaves_like "a filter by updated_since endpoint" do
      def set_updated_at(resource:, value:)
        resource.update_columns(api_unfunded_mentor_updated_at: value)
      end
    end
    it_behaves_like "a sortable endpoint" do
      def set_updated_at(resource:, value:)
        resource.update_columns(api_unfunded_mentor_updated_at: value)
      end

      def transform_sort_attribute(sort_attribute)
        if sort_attribute == "updated_at"
          "api_unfunded_mentor_updated_at"
        else
          sort_attribute
        end
      end
    end
    it_behaves_like "a N+1 queries free endpoint", :get
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_unfunded_mentor_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by updated_since endpoint"
    it_behaves_like "a N+1 queries free endpoint", :get
  end

  describe "email scoped to the requesting lead provider" do
    let(:other_active_lead_provider) do
      FactoryBot.create(
        :active_lead_provider,
        lead_provider: FactoryBot.create(:lead_provider),
        contract_period_year: active_lead_provider.contract_period_year
      )
    end
    let(:other_lead_provider) { other_active_lead_provider.lead_provider }

    let(:school_partnership_for_lead_provider) do
      lpdp = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
      FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lpdp)
    end
    let(:school_partnership_for_other_lead_provider) do
      lpdp = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: other_active_lead_provider)
      FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lpdp)
    end

    let(:mentor_teacher) { FactoryBot.create(:teacher, :with_realistic_name) }

    before do
      create_mentorship_period_for(
        mentee_school_partnership: school_partnership_for_lead_provider,
        mentor: mentor_teacher,
        create_mentor_training_period: false,
        refresh_metadata: true
      )
      mentor_teacher
        .mentor_at_school_periods
        .find_by(school: school_partnership_for_lead_provider.school)
        .update!(email: "lead-provider-school@example.com")

      create_mentorship_period_for(
        mentee_school_partnership: school_partnership_for_other_lead_provider,
        mentor: mentor_teacher,
        create_mentor_training_period: false,
        refresh_metadata: true
      )
      mentor_teacher
        .mentor_at_school_periods
        .find_by(school: school_partnership_for_other_lead_provider.school)
        .update!(email: "other-lead-provider-school@example.com")
    end

    it "returns the email tied to the school where the mentor mentors an ECT trained by the requesting lead provider" do
      authenticated_api_get(api_v3_unfunded_mentor_path(mentor_teacher.api_id))
      expect(response).to have_http_status(:ok)
      expect(parsed_response_data.dig(:attributes, :email)).to eq("lead-provider-school@example.com")
    end

    it "returns a different email when a different lead provider requests the same mentor" do
      other_token = API::TokenManager.create_lead_provider_api_token!(lead_provider: other_lead_provider).token
      authenticated_api_get(api_v3_unfunded_mentor_path(mentor_teacher.api_id), token: other_token)
      expect(response).to have_http_status(:ok)
      expect(parsed_response_data.dig(:attributes, :email)).to eq("other-lead-provider-school@example.com")
    end
  end
end
