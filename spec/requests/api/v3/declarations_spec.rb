RSpec.describe "Declarations API", :with_metadata, type: :request do
  let(:serializer) { API::DeclarationSerializer }
  let(:serializer_options) { { lead_provider_id: lead_provider.id } }
  let(:query) { API::Declarations::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:, teacher: nil, declaration_trait: :no_payment)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
    teacher ||= FactoryBot.create(:teacher)

    ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: 2.years.ago, finished_on: nil, teacher:, school: school_partnership.school)
    training_period = FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 1.year.ago, finished_on: nil, school_partnership:)

    declaration = FactoryBot.create(:declaration, declaration_trait, training_period:)
    declaration.payment_statement&.update!(active_lead_provider:)
    declaration
  end

  describe "#index" do
    let(:path) { api_v3_declarations_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a filter by multiple cohorts (contract_period year) endpoint"
    it_behaves_like "a filter by delivery_partner_id endpoint"
    it_behaves_like "a filter by participant_id endpoint"
    it_behaves_like "a filter by updated_since endpoint", updated_at_column: :updated_at
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_declaration_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by cohort endpoint"
    it_behaves_like "a does not filter by delivery_partner_id endpoint"
    it_behaves_like "a does not filter by participant_id endpoint"
    it_behaves_like "a does not filter by updated_since endpoint"
  end

  describe "#create" do
    let(:path) { api_v3_declarations_path }
    let(:service) { API::Declarations::Create }
    let(:resource_type) { Declaration }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
    let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:schedule) { FactoryBot.create(:schedule, contract_period: school_partnership.contract_period) }
    let(:milestone) { FactoryBot.create(:milestone, declaration_type: :started, schedule:) }
    let(:declaration_date) { Faker::Date.between(from: milestone.start_date, to: milestone.milestone_date) }

    let(:service_args) do
      {
        lead_provider_id: lead_provider.id,
        declaration_date: declaration_date.rfc3339,
        declaration_type: "started",
        evidence_type: "other",
        teacher_api_id: teacher.api_id,
        teacher_type:
      }
    end

    let(:params) do
      {
        data: {
          type: "participant-declaration",
          attributes: {
            participant_id: teacher.api_id,
            declaration_type: "started",
            declaration_date: declaration_date.rfc3339,
            course_identifier:,
            evidence_held: "other"
          }
        }
      }
    end

    %i[ect mentor].each do |teacher_type|
      context "for #{teacher_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{teacher_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now, teacher:) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{teacher_type}", :active, "#{teacher_type}_at_school_period": at_school_period, started_on: at_school_period.started_on.tomorrow, finished_on: at_school_period.finished_on, school_partnership:, schedule:) }
        let(:course_identifier) { teacher_type == :ect ? "ecf-induction" : "ecf-mentor" }
        let(:teacher_type) { teacher_type }

        it_behaves_like "a token authenticated endpoint", :post
        it_behaves_like "an API create endpoint"
      end
    end
  end

  describe "#void" do
    let(:path) { void_api_v3_declaration_path(resource.api_id) }
    let(:resource_type) { Declaration }
    let(:service_args) do
      {
        lead_provider_id: lead_provider.id,
        declaration_api_id: resource.api_id
      }
    end
    let(:params) { {} }

    context "when the declaration has been paid" do
      let(:resource) do
        create_resource(active_lead_provider:, declaration_trait: :paid)
      end
      let(:service) { API::Declarations::Clawback }

      it_behaves_like "a token authenticated endpoint", :put
      it_behaves_like "an API update endpoint", accepts_request_body: false
    end

    context "when the declaration has not been paid" do
      let(:resource) do
        create_resource(active_lead_provider:, declaration_trait: :payable)
      end
      let(:service) { API::Declarations::Void }

      it_behaves_like "a token authenticated endpoint", :put
      it_behaves_like "an API update endpoint", accepts_request_body: false
    end

    context "when the declaration is a previous declaration for a different lead provider" do
      let(:resource) { create_resource(active_lead_provider: FactoryBot.create(:active_lead_provider)) }

      before do
        # Close training periods for other lead providers.
        resource.teacher.ect_at_school_periods.update!(finished_on: 1.month.from_now)
        resource.teacher.ect_training_periods.update!(finished_on: 1.month.from_now)

        # Create a training period with the new lead provider in the future.
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: 2.months.from_now, finished_on: nil, teacher: resource.teacher)
        school_partnership = FactoryBot.create(:school_partnership, :for_year, lead_provider:)
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: nil, school_partnership:)
      end

      it "returns a 404 response" do
        # Ensure it is classed as a previous declaration.
        query = API::Declarations::Query.new(lead_provider_id: lead_provider.id)
        expect(query.declaration_by_api_id(resource.api_id)).not_to be_nil
        expect(resource.lead_provider).not_to eq(lead_provider)

        authenticated_api_put(path, params:)

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to eql("application/json; charset=utf-8")
        expect(response.body).to eq({ errors: [{ title: "Resource not found", detail: "Nothing could be found for the provided details" }] }.to_json)
      end
    end
  end
end
