# frozen_string_literal: true

RSpec.shared_examples "an API create endpoint (mocking)" do
  let(:params) { { data: { attributes: } } }
  let(:stub_service) do
    service_double = instance_double(service, "#{action}": resource)
    allow(service).to receive(:new) { |args|
      expect(args.to_hash.symbolize_keys).to eq(service_args) # rubocop:disable RSpec/ExpectInLet
    }.and_return(service_double)
    allow(service_double).to receive(:valid?).and_return(true)
    service_double
  end

  context "when authorized" do
    it "returns the resource" do
      serialized_response = { data: [{ id: "123" }] }
      allow(serializer).to receive(:render).with(resource, root: "data").and_return(serialized_response.to_json)
      stub_service

      api_post(path, params:)

      expect(response.status).to eq 200
      expect(response.content_type).to eql("application/json")
      expect(parsed_response).to eq(serialized_response)
    end

    it "calls the correct service" do
      service_double = stub_service

      api_post(path, params:)

      expect(service_double).to have_received(action)
    end

    it "calls the correct serializer" do
      stub_service

      expect(serializer).to receive(:render).with(resource, { root: "data" }).and_call_original

      api_post(path, params:)
    end

    context "when the service has errors", :exceptions_app do
      it "returns 422 - unprocessable entity" do
        errors = instance_double(ActiveModel::Errors, messages: { attr: %w[error] })
        service_double = instance_double(service, errors:)
        allow(service).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:valid?).and_return(false)

        api_post(path, params:)

        expect(response.status).to eq(422)
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_post(path, params:, token: "incorrect-token")

      expect(response.status).to eq 401
    end
  end
end
