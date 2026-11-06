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

  context "when the service raises RecordInvalid" do
    let(:errors) { instance_double(ActiveModel::Errors, messages: { attr: %w[message] }) }
    let(:service_double) { instance_double(service, errors:) }
    let(:validation_error) { ActiveRecord::RecordInvalid.new(resource_type.new) }

    before { allow(service).to receive(:new).and_return(service_double) }

    it "returns a 422 response if the service becomes invalid" do
      allow(service_double).to receive(:valid?).and_return(true, false)
      allow(service_double).to receive(service_action).and_raise(validation_error)

      authenticated_api_put(path, params:)

      expect(service_double).to have_received(:valid?).twice
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq({ errors: [{ title: "attr", detail: "message" }] }.to_json)
    end

    it "re-raises the original error if the service is still valid" do
      allow(service_double).to receive(:valid?).and_return(true)
      allow(service_double).to receive(service_action).and_raise(validation_error)
      allow(Rails.application).to receive(:env_config).and_wrap_original do |method|
        method.call.merge("action_dispatch.show_exceptions" => :none)
      end

      expect {
        authenticated_api_put(path, params:)
      }.to raise_error(ActiveRecord::RecordInvalid) { |raised| expect(raised).to equal(validation_error) }
      expect(service_double).to have_received(:valid?).twice
    end
  end

  it "does not rescue other errors" do
    service_double = instance_double(service, valid?: true)
    allow(service).to receive(:new).and_return(service_double)
    allow(service_double).to receive(service_action).and_raise(ActiveRecord::RecordNotUnique)

    expect {
      authenticated_api_put(path, params:)
    }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(service_double).to have_received(:valid?).once
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
