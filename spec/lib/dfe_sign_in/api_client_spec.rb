RSpec.shared_examples "DfE Sign In endpoint with error handling" do
  context "when the API returns a successful response" do
    let(:status) { 200 }
    let(:success) { true }

    it "does not raise an error" do
      expect { subject }.not_to raise_error
    end
  end

  context "when the API returns a 403" do
    let(:status) { 403 }
    let(:success) { false }
    let(:response_body) { "Forbidden" }

    it "raises a ForbiddenError" do
      expect { subject }.to raise_error(DfESignIn::APIClient::ForbiddenError)
    end
  end

  context "when the API returns a 404" do
    let(:status) { 404 }
    let(:success) { false }
    let(:response_body) { "Not Found" }

    it "raises a NotFoundError" do
      expect { subject }.to raise_error(DfESignIn::APIClient::NotFoundError)
    end
  end

  context "when the API returns a 500" do
    let(:status) { 500 }
    let(:success) { false }
    let(:response_body) { "Server Error" }

    it "raises an InternalServerError" do
      expect { subject }.to raise_error(DfESignIn::APIClient::InternalServerError)
    end
  end

  context "when the API returns an unexpected error code" do
    let(:status) { 418 }
    let(:success) { false }
    let(:response_body) { "I'm a teapot" }

    it "raises a generic ResponseError" do
      expect { subject }.to raise_error(DfESignIn::APIClient::ResponseError)
    end
  end
end

describe DfESignIn::APIClient do
  let(:fake_base_url) { "https://api.very-nice-website.org/" }
  let(:test_client_id) { "SomeService" }
  let(:fake_api_audience) { "signin.very-nice-website.org" }
  let(:fake_api_secret) { "ABC123" }

  let(:connection) { client.instance_variable_get(:@connection) }

  let(:success) { true }
  let(:status) { 200 }
  let(:response) { instance_double(Faraday::Response, success?: success, status:, body: response_body) }

  before do
    stub_const("ENV", {
      "DFE_SIGN_IN_API_BASE_URL" => fake_base_url,
      "DFE_SIGN_IN_CLIENT_ID" => test_client_id,
      "DFE_SIGN_IN_API_AUDIENCE" => fake_api_audience,
      "DFE_SIGN_IN_API_SECRET" => fake_api_secret,
    })

    allow(Rails.application.config).to receive(:dfe_sign_in_enabled).and_return(true)
  end

  describe "initialization" do
    it "fails unless config setting dfe_sign_in_enabled is true" do
      allow(Rails.application.config).to receive(:dfe_sign_in_enabled).and_return(false)

      expect { DfESignIn::APIClient.new }.to raise_error(DfESignIn::APIClient::DfESignInDisabled)
    end

    it "uses the env var DFE_SIGN_IN_API_BASE_URL as the default url" do
      api_client = DfESignIn::APIClient.new

      expect(api_client.connection.url_prefix.to_s).to eql(fake_base_url)
    end

    it "allows the url to be overridden" do
      replacement = "https://something-else.com/"
      api_client = DfESignIn::APIClient.new(url: replacement)

      expect(api_client.connection.url_prefix.to_s).to eql(replacement)
    end

    it "sets the timeout using the DEFAULT_TIMEOUT value by default" do
      api_client = DfESignIn::APIClient.new

      expect(api_client.connection.options.timeout).to eql(DfESignIn::APIClient::DEFAULT_TIMEOUT)
    end

    it "allows the timeout to be overridden" do
      api_client = DfESignIn::APIClient.new(timeout: 8)

      expect(api_client.connection.options.timeout).to be(8)
    end

    it "constructs the JWT using the correct values" do
      allow(JWT).to receive(:encode).and_return(true)

      DfESignIn::APIClient.new

      expect(JWT).to have_received(:encode).with(
        { iss: test_client_id, aud: fake_api_audience },
        fake_api_secret,
        "HS256"
      )
    end
  end

  describe "#organisations" do
    subject { client.organisations(user_id:) }

    let(:response_body) do
      [
        {
          "id" => "aaaaaaaa-bbbb-cccc-1111-222222222222",
          "name" => "Some Teaching School Hub",
          "LegalName" => nil,
          "category" => { "id" => "008", "name" => "Other Stakeholders" },
          "urn" => nil,
          "uid" => nil,
          "upin" => nil,
          "ukprn" => nil,
          "establishmentNumber" => nil,
          "status" => { "id" => 1, "name" => "Open" },
          "closedOn" => nil,
          "address" => "Something Road, Somewhere",
          "telephone" => nil,
          "statutoryLowAge" => nil,
          "statutoryHighAge" => nil,
          "legacyId" => "1111111",
          "companyRegistrationNumber" => "22222222",
          "SourceSystem" => nil,
          "providerTypeName" => nil,
          "ProviderTypeCode" => nil,
          "GIASProviderType" => nil,
          "PIMSProviderType" => nil,
          "PIMSProviderTypeCode" => nil,
          "PIMSStatusName" => nil,
          "pimsStatus" => nil,
          "GIASStatusName" => nil,
          "GIASStatus" => nil,
          "MasterProviderStatusName" => nil,
          "MasterProviderStatusCode" => nil,
          "OpenedOn" => nil,
          "DistrictAdministrativeName" => nil,
          "DistrictAdministrativeCode" => nil,
          "DistrictAdministrative_code" => nil,
          "IsOnAPAR" => nil
        }
      ]
    end

    let(:client) { DfESignIn::APIClient.new }
    let(:connection) { client.instance_variable_get(:@connection) }
    let(:user_id) { "b41b3462-62f8-4b43-8d4b-407f7f115056" }
    let(:expected_path) { %(/users/#{user_id}/organisations) }

    before do
      allow(connection).to receive(:get).with(expected_path).and_return(response)
    end

    include_examples "DfE Sign In endpoint with error handling"

    # GET https://environment-url/users/{user-id}/organisations
    it "calls the organisations endpoint" do
      subject

      expect(connection).to have_received(:get).with(expected_path)
    end

    it "returns an array of DfESignIn::Organisation" do
      expect(subject).to all(be_a(DfESignIn::Organisation))
    end
  end

  describe "#access_levels" do
    subject { client.access_levels(organisation_id:, user_id:, service_id:) }

    let(:user_id) { "55555555-9999-8888-7777-111111111111" }
    let(:organisation_id) { "55555555-4444-3333-2222-111111111111" }
    let(:service_id) { "55555555-4444-3333-9999-888888888888" }

    let(:response_body) do
      {
        "userId" => user_id,
        "userLegacyNumericId" => "77777",
        "userLegacyTextId" => "3333333",
        "serviceId" => service_id,
        "organisationId" => organisation_id,
        "organisationLegacyId" => "4444444",
        "roles" => [
          {
            "id" => "cccccccc-dddd-eeee-9999-888888888888",
            "name" => "Register ECTs",
            "code" => "registerECTsAccess",
            "numericId" => "22222",
            "status" => {
              "id" => 1,
            },
          },
        ],
        "identifiers" => []
      }
    end

    let(:client) { DfESignIn::APIClient.new }
    let(:connection) { client.instance_variable_get(:@connection) }
    let(:expected_path) { %(services/#{service_id}/organisations/#{organisation_id}/users/#{user_id}) }

    before do
      allow(connection).to receive(:get).with(expected_path).and_return(response)
    end

    include_examples "DfE Sign In endpoint with error handling"

    # GET https://environment-url/users/{user-id}/organisations
    it "calls the access levels endpoint" do
      subject

      expect(connection).to have_received(:get).with(expected_path)
    end

    it "returns a DfESignIn::AccessLevel" do
      access_level = subject

      expect(access_level).to be_a(DfESignIn::AccessLevel)
      expect(access_level.roles).to all(be_a(DfESignIn::AccessLevel::Role))
    end

    it "correctly sets the access level values" do
      access_level = subject

      expect(access_level.user_id).to eql(user_id)
      expect(access_level.organisation_id).to eql(organisation_id)
      expect(access_level.service_id).to eql(service_id)
      expect(access_level.roles.map(&:name)).to include("Register ECTs")
    end
  end

  describe "#users" do
    subject { client.users }

    let(:response_body) do
      {
        "users": [
          {
            "approvedAt" => "2019-06-19T15:09:58.683Z",
            "updatedAt" => "2019-06-19T15:09:58.683Z",
            "organisation": {
              "id" => "13F20E54-79EA-4146-8E39-18197576F023",
              "name" => "Department for Education",
              "Category" => "002",
              "Type": nil,
              "URN": nil,
              "UID": nil,
              "UKPRN": nil,
              "EstablishmentNumber" => "001",
              "Status": 1,
              "ClosedOn": nil,
              "Address": nil,
              "phaseOfEducation": nil,
              "statutoryLowAge": nil,
              "statutoryHighAge": nil,
              "telephone": nil,
              "regionCode": nil,
              "legacyId" => "1031237",
              "companyRegistrationNumber" => "1234567",
              "ProviderProfileID" => "",
              "UPIN" => "",
              "PIMSProviderType" => "Central Government Department",
              "PIMSStatus" => "",
              "DistrictAdministrativeName" => "",
              "OpenedOn" => "2007-09-01T00:00:00.0000000Z",
              "SourceSystem" => "",
              "ProviderTypeName" => "Government Body",
              "GIASProviderType" => "",
              "PIMSProviderTypeCode" => "",
              "createdAt" => "2019-02-20T14:27:59.020Z",
              "updatedAt" => "2019-02-20T14:28:38.223Z"
            },
            "roles": [
              {
                "id" => "FA3DDF63-6D48-41BB-8706-1048B24D4744",
                "name" => "Test Service - Example role",
                "code" => "TEST",
                "numericId" => "12345",
                "status": 1
              }
            ],
            "roleName" => "Approver",
            "roleId": 10_000,
            "userId" => "21D62132-6570-4E63-9DCB-137CC35E7543",
            "userStatus": 1,
            "email" => "foo@example.com",
            "familyName" => "Johnson",
            "givenName" => "Roger"
          }
        ],
        "numberOfRecords": 1,
        "page": 1,
        "numberOfPages": 1
      }
    end

    let(:client) { DfESignIn::APIClient.new }
    let(:connection) { client.instance_variable_get(:@connection) }
    let(:expected_path) { %(/users) }

    before do
      allow(connection).to receive(:get).with(expected_path).and_return(response)
    end

    include_examples "DfE Sign In endpoint with error handling"

    it "calls the users endpoint" do
      subject

      expect(connection).to have_received(:get).with(expected_path)
    end

    it "returns the response body" do
      expect(subject).to eql(response_body)
    end
  end

  describe "#roles" do
    subject { client.roles(service_id:) }

    let(:response_body) do
      [
        {
          "name" => "Role 1 Name",
          "code" => "Role1Code",
          "status" => "Active"
        },
        {
          "name" => "Role 2 Name",
          "code" => "Role2Code",
          "status" => "Inactive"
        }
      ]
    end

    let(:client) { DfESignIn::APIClient.new }
    let(:connection) { client.instance_variable_get(:@connection) }
    let(:service_id) { "55555555-4444-3333-9999-888888888888" }
    let(:expected_path) { %(/services/#{service_id}/roles) }

    before do
      allow(connection).to receive(:get).with(expected_path).and_return(response)
    end

    include_examples "DfE Sign In endpoint with error handling"

    it "calls the roles endpoint" do
      subject

      expect(connection).to have_received(:get).with(expected_path)
    end

    it "returns an array of roles" do
      expect(subject).to all(include("name", "code", "status"))
    end
  end
end
