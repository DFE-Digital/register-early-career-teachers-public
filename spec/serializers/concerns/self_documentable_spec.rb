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
    expect(self_documentable.openapi_schema_name).to eq("User")
    expect(self_documentable.openapi_ref).to eq("$ref": "#/components/schemas/User")
    expect(self_documentable.openapi_schema_definition).to eq("User" => self_documentable.openapi_schema)
  end

  it "omits the API namespace and version from versioned schema names by default" do
    expect(API::Induction::V1::AppropriateBodySerializer.openapi_schema_name).to eq("AppropriateBody")
  end

  it "retains the namespace when requested" do
    expect(API::OAuth::ErrorSerializer.openapi_schema_name(include_namespace: true)).to eq("OAuthError")
    expect(API::OAuth::ErrorSerializer.openapi_ref(include_namespace: true)).to eq("$ref": "#/components/schemas/OAuthError")
    expect(API::OAuth::ErrorSerializer.openapi_schema_definition(include_namespace: true)).to eq("OAuthError" => API::OAuth::ErrorSerializer.openapi_schema)
  end
end
