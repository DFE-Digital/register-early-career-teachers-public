RSpec.describe "Participants API", :with_metadata, type: :request do
  let(:serializer) { API::TeacherSerializer }
  let(:serializer_options) { { lead_provider_id: lead_provider.id } }
  let(:query) { API::Teachers::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:, from_participant_id: nil, training_status: nil)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
    ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: 2.years.ago, finished_on: nil)
    training_period = FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 1.year.ago, finished_on: nil, school_partnership:)
    training_period.update!(withdrawn_at: 1.day.ago, withdrawal_reason: :other) if training_status == :withdrawn
    training_period.update!(deferred_at: 1.day.ago, deferral_reason: :other) if training_status == :deferred

    training_period.trainee.teacher.tap do |teacher|
      FactoryBot.create(:teacher_id_change, teacher:, api_from_teacher_id: from_participant_id) if from_participant_id
    end
  end

  describe "#index" do
    let(:path) { api_v3_participants_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a filter by multiple cohorts (contract_period year) endpoint"
    it_behaves_like "a filter by from_participant_id endpoint"
    it_behaves_like "a filter by training_status endpoint"
    # it_behaves_like "a filter by updated_since endpoint" TODO: uncomment when Teacher has an api_updated_at
    # it_behaves_like "a sortable endpoint" TODO: uncomment when Teacher has an api_updated_at
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_participant_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    # it_behaves_like "a does not filter by updated_since endpoint" # TODO: uncomment when Teacher has an api_updated_at
  end

  describe "#change_schedule" do
    let(:path) { change_schedule_api_v3_participant_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#defer" do
    let(:path) { defer_api_v3_participant_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#resume" do
    let(:path) { resume_api_v3_participant_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#withdraw" do
    let(:path) { withdraw_api_v3_participant_path(resource.api_id) }
    let(:service) { API::Teachers::Withdraw }
    let(:resource_type) { Teacher }
    let(:resource) { create_resource(active_lead_provider:) }
    let(:reason) { service::WITHDRAWAL_REASONS.sample }
    let(:course_identifier) { "ecf-induction" }
    let(:service_args) do
      {
        lead_provider_id: lead_provider.id,
        teacher_api_id: resource.api_id,
        reason:,
        course_identifier:
      }
    end
    let(:params) do
      {
        data: {
          type: "participant-withdraw",
          attributes: {
            reason:,
            course_identifier:,
          }
        }
      }
    end

    it_behaves_like "a token authenticated endpoint", :put
    it_behaves_like "an API update endpoint"
  end
end
