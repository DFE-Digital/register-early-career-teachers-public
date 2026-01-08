RSpec.shared_examples "an API create endpoint" do
  let(:options) { defined?(serializer_options) ? serializer_options : {} }

  it "creates and returns the resource in a serialized format" do
    expect { authenticated_api_post(path, params:) }.to change(resource_type, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource_type.last, root: "data", **options))
  end

  it "calls the service with the correct arguments" do
    allow(service).to receive(:new).and_call_original

    authenticated_api_post(path, params:)

    expect(service).to have_received(:new).with(service_args)
  end

  it "returns a 422 response if the service has errors" do
    errors = instance_double(ActiveModel::Errors, messages: { attr: %w[message] })
    service_double = instance_double(service, valid?: false, errors:)
    allow(service).to receive(:new).and_return(service_double)

    authenticated_api_post(path, params:)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "attr", detail: "message" }] }.to_json)
  end

  it "returns a 400 response if the request body is malformed" do
    authenticated_api_post(path, params: { not_a_valid: :body })

    expect(response).to have_http_status(:bad_request)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "Bad request", detail: "Correct json data structure required. See API docs for reference." }] }.to_json)
  end

  context "when extra params are sent" do
    it "calls the service with the correct arguments" do
      allow(service).to receive(:new).and_call_original

      authenticated_api_post(path, params: params.deep_merge(data: { attributes: { any_param1: "test", any_param2: "test" } }))

      expect(service).to have_received(:new).with(service_args)
    end
  end
end
