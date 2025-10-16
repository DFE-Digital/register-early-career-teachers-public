module DfESignIn
  class FakeAPIClient
    attr_reader :role_codes

    def initialize(role_codes: [])
      @role_codes = role_codes
    end

    def access_levels(organisation_id:, user_id:, service_id: "abc123")
      DfESignIn::AccessLevel.from_response_body(
        {
          "userId" => user_id,
          "serviceId" => service_id,
          "organisationId" => organisation_id,
          "roles" => roles
        }
      )
    end

    private

    def roles
      role_codes.map do |role_code|
        {
          "id" => SecureRandom.uuid,
          "name" => "Role for #{role_code}",
          "code" => role_code,
          "numericId" => rand(1000..9999).to_s,
          "status" => {
            "id" => 1
          }
        }
      end
    end
  end
end
