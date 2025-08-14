module Organisation
  class Access
    attr_reader :user_id, :organisation_id

    def initialize(user_id:, organisation_id:)
      @user_id = user_id
      @organisation_id = organisation_id
    end

    def can_access?
      Rails.logger.info(access_level)
      access_level.roles.any?
    end

  private

    def access_level
      @access_level ||= dfe_sign_in_api_client.access_levels(organisation_id:, user_id:)
    end

    def dfe_sign_in_api_client
      @dfe_sign_in_api_client ||= DfESignIn::APIClient.new
    end
  end
end
