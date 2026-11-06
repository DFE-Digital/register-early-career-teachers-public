RSpec.shared_examples "an API update endpoint" do |example_options|
  let(:options) { defined?(serializer_options) ? serializer_options : {} }

  it "updates and returns the resource in a serialized format" do
    authenticated_api_put(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource_type.last.reload, root: "data", **options))
  end

  it "calls the service with the correct arguments" do
    allow(service).to receive(:new).and_call_original

    authenticated_api_put(path, params:)

    expect(service).to have_received(:new).with(service_args)
  end

  it "returns a 422 response if the service has errors" do
    errors = instance_double(ActiveModel::Errors, messages: { attr: %w[message] })
    service_double = instance_double(service, valid?: false, errors:)
    allow(service).to receive(:new).and_return(service_double)

    authenticated_api_put(path, params:)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "attr", detail: "message" }] }.to_json)
  end

  it "returns a 422 response if underlying models have errors" do
    error = ActiveRecord::RecordInvalid.new(resource_type.new)
    service_double = instance_double(service, valid?: true)
    allow(service).to receive(:new).and_return(service_double)
    allow(service_double).to receive(service_action).and_raise(error)

    authenticated_api_put(path, params:)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({
      errors: [{
        title: "Unprocessable content",
        detail: "We could not process this request. Check the details and try again. Contact the DfE for support if the problem persists."
      }]
    }.to_json)
  end

  it "does not rescue other service errors" do
    service_double = instance_double(service, valid?: true)
    allow(service).to receive(:new).and_return(service_double)
    allow(service_double).to receive(service_action).and_raise(ActiveRecord::RecordNotUnique)

    expect { authenticated_api_put(path, params:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  unless example_options && example_options[:accepts_request_body] == false
    it "returns a 400 response if the request body is malformed" do
      authenticated_api_put(path, params: { not_a_valid: :body })

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq({ errors: [{ title: "Bad request", detail: "Correct json data structure required. See API docs for reference." }] }.to_json)
    end
  end

  context "when the resource has a different lead provider" do
    let(:resource) { create_resource(framework_agreement: FactoryBot.create(:framework_agreement)) }

    it "returns a 404 response" do
      authenticated_api_put(path, params:)

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq({ errors: [{ title: "Resource not found", detail: "Nothing could be found for the provided details" }] }.to_json)
    end
  end

  context "when extra params are sent" do
    it "calls the service with the correct arguments" do
      allow(service).to receive(:new).and_call_original

      authenticated_api_put(path, params: params.deep_merge(data: { attributes: { any_param1: "test", any_param2: "test" } }))

      expect(service).to have_received(:new).with(service_args)
    end
  end
end
