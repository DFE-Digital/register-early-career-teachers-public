module DfESignIn
  class AccessLevel
    Role = Data.define(:id, :name, :code, :numeric_id)

    attr_reader :user_id, :service_id, :organisation_id, :roles

    def initialize(user_id:, service_id:, organisation_id:, roles:)
      @user_id = user_id
      @service_id = service_id
      @organisation_id = organisation_id
      @roles = roles
    end

    def self.from_response_body(hash)
      new(
        user_id: hash.fetch('userId'),
        service_id: hash.fetch('serviceId'),
        organisation_id: hash.fetch('organisationId'),
        roles: hash.fetch('roles').map do |r|
          Role.new(
            id: r.fetch('id'),
            name: r.fetch('name'),
            code: r.fetch('code'),
            numeric_id: r.fetch('numericId')
          )
        end
      )
    end

    def has_register_ect_access_role?
      roles.any? { |r| r.code == 'registerECTsAccess' }
    end
  end
end
