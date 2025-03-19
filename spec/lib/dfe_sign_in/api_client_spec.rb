describe DfESignIn::APIClient do
  let(:fake_base_url) { 'https://api.very-nice-website.org/' }
  let(:fake_client_id) { 'SomeService' }
  let(:fake_api_audience) { 'signin.very-nice-website.org' }
  let(:fake_api_secret) { 'ABC123' }

  let(:connection) { client.instance_variable_get(:@connection) }
  let(:response) { instance_double(Faraday::Response, success?: true, body: response_body) }

  before do
    stub_const('ENV', {
      'DFE_SIGN_IN_API_BASE_URL' => fake_base_url,
      'DFE_SIGN_IN_CLIENT_ID' => fake_client_id,
      'DFE_SIGN_IN_API_AUDIENCE' => fake_api_audience,
      'DFE_SIGN_IN_API_SECRET' => fake_api_secret,
    })

    allow(Rails.application.config).to receive(:dfe_sign_in_enabled).and_return(true)
  end

  describe 'initialization' do
    it 'fails unless config setting dfe_sign_in_enabled is true' do
      allow(Rails.application.config).to receive(:dfe_sign_in_enabled).and_return(false)

      expect { DfESignIn::APIClient.new }.to raise_error(DfESignIn::APIClient::DfESignInDisabled)
    end

    it 'uses the env var DFE_SIGN_IN_API_BASE_URL as the default url' do
      api_client = DfESignIn::APIClient.new

      expect(api_client.connection.url_prefix.to_s).to eql(fake_base_url)
    end

    it 'allows the url to be overridden' do
      replacement = 'https://something-else.com/'
      api_client = DfESignIn::APIClient.new(url: replacement)

      expect(api_client.connection.url_prefix.to_s).to eql(replacement)
    end

    it 'sets the timeout using the DEFAULT_TIMEOUT value by default' do
      api_client = DfESignIn::APIClient.new

      expect(api_client.connection.options.timeout).to eql(DfESignIn::APIClient::DEFAULT_TIMEOUT)
    end

    it 'allows the timeout to be overridden' do
      api_client = DfESignIn::APIClient.new(timeout: 8)

      expect(api_client.connection.options.timeout).to be(8)
    end

    it 'constructs the JWT using the correct values' do
      allow(JWT).to receive(:encode).and_return(true)

      DfESignIn::APIClient.new

      expect(JWT).to have_received(:encode).with(
        { iss: fake_client_id, aud: fake_api_audience },
        fake_api_secret,
        'HS256'
      )
    end
  end

  describe '#organisations' do
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
    let(:user_id) { 'b41b3462-62f8-4b43-8d4b-407f7f115056' }
    let(:expected_path) { %(/users/#{user_id}/organisations) }
    let(:response) { instance_double(Faraday::Response, success?: true, body: response_body) }

    before do
      allow(connection).to receive(:get).with(expected_path).and_return(response)
    end

    # GET https://environment-url/users/{user-id}/organisations
    it 'calls the organisations endpoint' do
      client.organisations(user_id:)

      expect(connection).to have_received(:get).with(expected_path)
    end

    it 'returns an array of DfESignIn::Organisation' do
      output = client.organisations(user_id:)

      expect(output).to all(be_a(DfESignIn::Organisation))
    end
  end

  describe '#access_levels' do
    let(:user_id) { '55555555-9999-8888-7777-111111111111' }
    let(:organisation_id) { '55555555-4444-3333-2222-111111111111' }
    let(:service_id) { '55555555-4444-3333-9999-888888888888' }

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
    let(:response) { instance_double(Faraday::Response, success?: true, body: response_body) }

    before do
      allow(connection).to receive(:get).with(expected_path).and_return(response)
    end

    # GET https://environment-url/users/{user-id}/organisations
    it 'calls the access levels endpoint' do
      client.access_levels(service_id:, organisation_id:, user_id:)

      expect(connection).to have_received(:get).with(expected_path)
    end

    it 'returns a DfESignIn::AccessLevel' do
      access_level = client.access_levels(service_id:, organisation_id:, user_id:)

      expect(access_level).to be_a(DfESignIn::AccessLevel)
      expect(access_level.roles).to all(be_a(DfESignIn::AccessLevel::Role))
    end

    it 'correctly sets the access level values' do
      access_level = client.access_levels(service_id:, organisation_id:, user_id:)

      expect(access_level.user_id).to eql(user_id)
      expect(access_level.organisation_id).to eql(organisation_id)
      expect(access_level.service_id).to eql(service_id)
      expect(access_level.roles.map(&:name)).to include('Register ECTs')
    end
  end
end
