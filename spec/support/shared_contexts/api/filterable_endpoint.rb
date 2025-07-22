RSpec.shared_examples "a filter by multiple cohorts (contract_period year) endpoint" do
  it "returns only resources for the specified cohorts" do
    previous_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year - 1)
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)

    previous_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)

    previous_contract_period_resource = create_resource(active_lead_provider: previous_active_lead_provider)
    next_contract_period_resource = create_resource(active_lead_provider: next_active_lead_provider)

    # Resource for the current contract_period should not be included.
    create_resource(active_lead_provider:)

    authenticated_api_get(path, params: { filter: { cohort: "#{previous_contract_period.year},#{next_contract_period.year}" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([previous_contract_period_resource, next_contract_period_resource]), root: "data"))
  end

  it "ignores invalid cohorts" do
    resource = create_resource(active_lead_provider:)

    # Resource for the next contract_period should not be included.
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
    create_resource(active_lead_provider: next_active_lead_provider)

    authenticated_api_get(path, params: { filter: { cohort: "#{active_lead_provider.contract_period.year},invalid,cohort" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([resource]), root: "data"))
  end
end

RSpec.shared_examples "a filter by updated_since endpoint" do
  let!(:resource_updated_one_week_ago) { travel_to(1.week.ago) { create_resource(active_lead_provider:) } }
  let!(:resource_updated_one_month_ago) { travel_to(1.month.ago) { create_resource(active_lead_provider:) } }

  before do
    # Resource updated more than two months ago should not be included.
    travel_to(3.months.ago) { create_resource(active_lead_provider:) }
  end

  it "returns only resource that have been updated since the provided date" do
    updated_since = 2.months.ago.utc.iso8601
    params = { filter: { updated_since: } }
    params.deep_merge!(mandatory_params) if defined?(mandatory_params)
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([resource_updated_one_week_ago, resource_updated_one_month_ago]), root: "data"))
  end

  it "correctly decodes URL encoded dates" do
    updated_since = URI.encode_www_form_component(2.months.ago.iso8601)
    params = { filter: { updated_since: } }
    params.deep_merge!(mandatory_params) if defined?(mandatory_params)
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([resource_updated_one_week_ago, resource_updated_one_month_ago]), root: "data"))
  end

  it "returns 400 bad request when the updated_since is not a valid date" do
    params = { filter: { updated_since: "invalid-date" } }
    params.deep_merge!(mandatory_params) if defined?(mandatory_params)
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:bad_request)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "Bad request", detail: "The filter '#/updated_since' must be a valid ISO 8601 date" }] }.to_json)
  end
end

RSpec.shared_examples "a filter by a single cohort (contract_period year) endpoint" do
  it "returns only resources for the specified cohort" do
    previous_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year - 1)
    previous_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period)
    previous_contract_period_resource = create_resource(active_lead_provider: previous_active_lead_provider)

    # Resource for the current contract_period should not be included.
    create_resource(active_lead_provider:)

    authenticated_api_get(path, params: { filter: { cohort: previous_contract_period.year } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([previous_contract_period_resource]), root: "data"))
  end

  it "ignores invalid cohorts" do
    resource = create_resource(active_lead_provider:)

    # Resource for the next contract_period should not be included.
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
    create_resource(active_lead_provider: next_active_lead_provider)

    authenticated_api_get(path, params: { filter: { cohort: "#{active_lead_provider.contract_period.year},invalid,cohort" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([resource]), root: "data"))
  end
end

RSpec.shared_examples "a filter by lead provider endpoint" do
  let(:resource) do
    lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
    contract_period = active_lead_provider.contract_period
    create_resource(active_lead_provider: FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:))
  end

  it "returns only resources for the specified lead provider" do
    params = {}
    params.merge!(mandatory_params) if defined?(mandatory_params)
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:not_found)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "Resource not found", detail: "Nothing could be found for the provided details" }] }.to_json)
  end
end
