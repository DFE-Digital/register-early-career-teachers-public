# frozen_string_literal: true

shared_examples "an API create endpoint" do
  context "when authorized" do
    it "calls the service and returns the created resource in the serialized format" do
      params = { data: { attributes: } }

      expect { api_post(path, params:) }.to change(resource_type, :count).by(1)

      created_resource = resource_type.last

      expect(response.status).to eq 200
      expect(response.content_type).to eql("application/json")
      expect(response.body).to eq(serializer.render(created_resource, root: "data"))

      assert_on_created_resource(created_resource)
    end

    it "returns errors when the request body is invalid" do
      key_with_error = attributes.keys.sample
      invalid_attributes = { key_with_error => SecureRandom.uuid }
      params = { data: { attributes: attributes.merge(invalid_attributes) } }

      api_post(path, params:)

      expect(response.status).to eq(422)
      expect(parsed_response[:errors]).to be_present
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_post(path, token: "incorrect-token")

      expect(response.status).to eq 401
    end
  end
end
