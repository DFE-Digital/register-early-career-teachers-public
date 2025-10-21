RSpec.shared_examples "a filter by multiple cohorts (contract_period year) endpoint" do
  let(:options) { defined?(serializer_options) ? serializer_options : {} }

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
    expect(response.body).to eq(serializer.render(apply_expected_order([previous_contract_period_resource.reload, next_contract_period_resource.reload]), root: "data", **options))
  end

  it "ignores invalid cohorts" do
    resource = create_resource(active_lead_provider:)

    # Resource for the next contract_period should not be included.
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
    create_resource(active_lead_provider: next_active_lead_provider)

    authenticated_api_get(path, params: { filter: { cohort: "#{active_lead_provider.contract_period.year},invalid,cohort,,20A1,nil,null, ,1099,#{SecureRandom.uuid}" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **options))
  end

  it "returns all resources when cohort is blank" do
    resource = create_resource(active_lead_provider:)

    authenticated_api_get(path, params: { filter: { cohort: "" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **options))
  end

  it "returns no resources when cohort contains no valid contract period years" do
    create_resource(active_lead_provider:)

    authenticated_api_get(path, params: { filter: { cohort: "invalid" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([], root: "data", **options))
  end
end

RSpec.shared_examples "a filter by updated_since endpoint" do
  let(:options) { defined?(serializer_options) ? serializer_options : {} }
  let!(:resource_updated_one_week_ago) { create_resource(active_lead_provider:).tap { it.update_columns(api_updated_at: 1.week.ago) } }
  let!(:resource_updated_one_month_ago) { create_resource(active_lead_provider:).tap { it.update_columns(api_updated_at: 1.month.ago) } }

  before do
    # Resource updated more than two months ago should not be included.
    create_resource(active_lead_provider:).update_columns(api_updated_at: 3.months.ago)
  end

  it "returns only resource that have been updated since the provided date" do
    updated_since = 2.months.ago.utc.iso8601
    params = { filter: { updated_since: } }

    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([resource_updated_one_week_ago.reload, resource_updated_one_month_ago.reload]), root: "data", **options))
  end

  it "correctly decodes URL encoded dates" do
    updated_since = URI.encode_www_form_component(2.months.ago.iso8601)
    params = { filter: { updated_since: } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(apply_expected_order([resource_updated_one_week_ago.reload, resource_updated_one_month_ago.reload]), root: "data", **options))
  end

  it "returns 400 bad request when the updated_since is not a valid date" do
    params = { filter: { updated_since: "invalid-date" } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:bad_request)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "Bad request", detail: "The filter '#/updated_since' must be a valid ISO 8601 date" }] }.to_json)
  end
end

RSpec.shared_examples "a filter by a single cohort (contract_period year) endpoint" do
  it "returns only resources for the specified cohort" do
    resource = create_resource(active_lead_provider:)

    # Resource for the next contract_period should not be included.
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
    create_resource(active_lead_provider: next_active_lead_provider)

    authenticated_api_get(path, params: { filter: { cohort: active_lead_provider.contract_period.year.to_s } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **serializer_options))
  end

  it "returns no resources if the specified cohort is invalid" do
    create_resource(active_lead_provider:)

    # Resource for the next contract_period should not be included.
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
    create_resource(active_lead_provider: next_active_lead_provider)

    authenticated_api_get(path, params: { filter: { cohort: "invalid" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([], root: "data", **serializer_options))
  end

  it "returns no resources if the specified cohort is not found" do
    create_resource(active_lead_provider:)

    # Resource for the next contract_period should not be included.
    next_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    next_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: next_contract_period)
    create_resource(active_lead_provider: next_active_lead_provider)

    authenticated_api_get(path, params: { filter: { cohort: "1999" } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([], root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a filter by urn endpoint" do
  it "returns only resources for the specified urn" do
    resource = create_resource(active_lead_provider:)

    # Resource with another urn should not be included.
    create_resource(active_lead_provider:)

    params = { filter: { urn: resource.urn } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **serializer_options))
  end

  it "ignores invalid urns" do
    resource = create_resource(active_lead_provider:)

    # Resource with another urn should not be included.
    create_resource(active_lead_provider:)

    params = { filter: { urn: "#{resource.urn},invalid" } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a filter by from_participant_id endpoint" do
  it "returns only resources that have the specified from_participant_id" do
    teacher = FactoryBot.create(:teacher)
    resource = create_resource(active_lead_provider:, from_participant_id: teacher.api_id)

    # Resource with another from_participant_id should not be included.
    other_teacher = FactoryBot.create(:teacher)
    create_resource(active_lead_provider:, from_participant_id: other_teacher.api_id)

    params = { filter: { from_participant_id: teacher.api_id } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **serializer_options))
  end

  it "returns no resources if the from_participant_id is not found" do
    teacher = FactoryBot.create(:teacher)
    create_resource(active_lead_provider:, from_participant_id: teacher.api_id)

    params = { filter: { from_participant_id: SecureRandom.uuid } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([], root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a filter by training_status endpoint" do
  it "returns only resources that have the specified training_status" do
    deferred_resource = create_resource(active_lead_provider:, training_status: :deferred)

    # Resource with another training_status should not be included.
    create_resource(active_lead_provider:, training_status: :withdrawn)

    params = { filter: { training_status: :deferred } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([deferred_resource.reload], root: "data", **serializer_options))
  end

  it "returns no resources if the training_status is not found" do
    create_resource(active_lead_provider:, training_status: :deferred)
    create_resource(active_lead_provider:, training_status: :withdrawn)

    params = { filter: { training_status: "invalid" } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([], root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a does not filter by cohort endpoint" do
  it "returns the resources, ignoring the `cohort`" do
    different_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period.year + 1)
    authenticated_api_get(path, params: { filter: { cohort: different_contract_period.year.to_s } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource.reload, root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a does not filter by updated_since endpoint" do
  let(:options) { defined?(serializer_options) ? serializer_options : {} }

  it "returns the resources, ignoring the `updated_since`" do
    updated_since_after_resource_updated_at = (resource.api_updated_at + 1.day).utc.iso8601
    authenticated_api_get(path, params: { filter: { updated_since: updated_since_after_resource_updated_at } })

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource.reload, root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a filter by delivery_partner_id endpoint" do
  it "returns only resources for the specified delivery_partner_id" do
    resource = create_resource(active_lead_provider:)

    # Resource with another delivery_partner_id should not be included.
    create_resource(active_lead_provider:)

    params = { filter: { delivery_partner_id: resource.delivery_partner.api_id } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **serializer_options))
  end

  it "ignores invalid delivery partner ids" do
    resource = create_resource(active_lead_provider:)

    # Resource with another delivery_partner_id should not be included.
    create_resource(active_lead_provider:)

    params = { filter: { delivery_partner_id: "#{resource.delivery_partner.api_id},invalid" } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render([resource.reload], root: "data", **serializer_options))
  end
end

RSpec.shared_examples "a does not filter by delivery_partner_id endpoint" do
  let(:options) { defined?(serializer_options) ? serializer_options : {} }

  it "returns the resources, ignoring the `delivery_partner_id`" do
    # Use of a filter with a different delivery_partner_id should not change the resource returned.
    different_resource = create_resource(active_lead_provider:)

    params = { filter: { delivery_partner_id: different_resource.delivery_partner.api_id } }
    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource.reload, root: "data", **serializer_options))
  end
end
