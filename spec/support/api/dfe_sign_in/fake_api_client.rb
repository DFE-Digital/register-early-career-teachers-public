module DfESignIn
  class FakeAPIClient
    attr_reader :role_code

    def initialize(role_code: 'registerECTsAccess')
      @role_code = role_code
    end

    def access_levels(organisation_id:, user_id:, service_id: 'abc123')
      DfESignIn::AccessLevel.from_response_body(
        {
          "userId" => user_id,
          "serviceId" => service_id,
          "organisationId" => organisation_id,
          "roles" => [
            {
              "id" => "role-1",
              "name" => "Role A",
              "code" => role_code,
              "numericId" => "1234",
              "status" => {
                "id" => 1
              }
            }
          ]
        }
      )
    end
  end
end
