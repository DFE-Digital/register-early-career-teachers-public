RSpec.shared_examples "an API update endpoint" do
  let(:options) { defined?(serializer_options) ? serializer_options : {} }

  it "creates and returns the resource in a serialized format" do
    authenticated_api_put(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource_type.last, root: "data", **options))
  end

  it "calls the service with the correct arguments" do
    allow(service).to receive(:new).and_call_original

    authenticated_api_put(path, params:)

    expect(service).to have_received(:new).with(service_args)
  end

  it "returns a 422 response if the service has errors" do
    errors = instance_double(ActiveModel::Errors, messages: {attr: %w[message]})
    service_double = instance_double(service, valid?: false, errors:)
    allow(service).to receive(:new).and_return(service_double)

    authenticated_api_put(path, params:)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({errors: [{title: "attr", detail: "message"}]}.to_json)
  end

  it "returns a 400 response if the request body is malformed" do
    authenticated_api_put(path, params: {not_a_valid: :body})

    expect(response).to have_http_status(:bad_request)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({errors: [{title: "Bad request", detail: "Correct json data structure required. See API docs for reference."}]}.to_json)
  end

  it "returns a 404 response if the resource does not belong to the lead provider" do
    resource.update!(active_lead_provider: FactoryBot.create(:active_lead_provider))

    authenticated_api_put(path, params:)

    expect(response).to have_http_status(:not_found)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({errors: [{title: "Resource not found", detail: "Nothing could be found for the provided details"}]}.to_json)
  end
end
