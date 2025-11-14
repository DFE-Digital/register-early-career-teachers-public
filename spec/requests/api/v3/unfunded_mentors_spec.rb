RSpec.describe "Unfunded mentors API", :with_metadata, type: :request do
  let(:serializer) { API::UnfundedMentorSerializer }
  let(:serializer_options) { { lead_provider_id: lead_provider.id } }
  let(:query) { API::Teachers::UnfundedMentors::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_mentorship_period(mentor_school_partnership:, mentee_school_partnership:)
    mentee = FactoryBot.create(:teacher)
    mentee_school_period = FactoryBot.create(:ect_at_school_period, :ongoing, teacher: mentee, started_on: 2.months.ago)
    FactoryBot.create(:training_period, :for_ect, started_on: 1.month.ago, ect_at_school_period: mentee_school_period, school_partnership: mentee_school_partnership)

    unfunded_mentor = FactoryBot.create(:teacher)
    unfunded_mentor_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: unfunded_mentor, started_on: 2.months.ago)
    FactoryBot.create(:training_period, :for_mentor, started_on: 1.month.ago, mentor_at_school_period: unfunded_mentor_school_period, school_partnership: mentor_school_partnership)

    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: mentee_school_period,
      mentor: unfunded_mentor_school_period
    )
  end

  def create_resource(active_lead_provider:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
    other_school_partnership = FactoryBot.create(:school_partnership)

    # Unfunded mentor associated with the lead provider (should be returned)
    create_mentorship_period(mentor_school_partnership: other_school_partnership, mentee_school_partnership: school_partnership).mentor.teacher
  end

  describe "#index" do
    let(:path) { api_v3_unfunded_mentors_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a filter by updated_since endpoint"
    it_behaves_like "a sortable endpoint"
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
