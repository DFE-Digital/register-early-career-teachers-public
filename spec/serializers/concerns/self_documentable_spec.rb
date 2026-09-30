RSpec.describe SelfDocumentable do
  subject(:self_documentable) { API::Hello::UserSerializer }

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }

  it { is_expected.to include(SelfDocumentable) }

  it "builds an OpenAPI schema from the declared fields" do
    expect(self_documentable.openapi_schema).to eq(
      description: "Test API for APIs restricted by the OAuth access token.",
      type: :object,
      required: %i[name],
      properties: {
        name: {
          type: :string,
          description: "The appropriate body name.",
          example: "Golden Leaf Teaching School Hub"
        },
      }
    )
  end

  it "serializes the fields it documents" do
    expect(self_documentable.render_as_hash(authorization)).to eq(name: "Golden Leaf Teaching School Hub")
  end

  it "names and references the schema after the serializer" do
    expect(self_documentable.openapi_schema_name).to eq("HelloUser")
    expect(self_documentable.openapi_ref).to eq("$ref": "#/components/schemas/HelloUser")
    expect(self_documentable.openapi_schema_definition).to eq("HelloUser" => self_documentable.openapi_schema)
  end
end
