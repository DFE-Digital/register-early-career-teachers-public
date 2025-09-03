module Organisation
  # DfE Sign In policies and roles
  #
  # 1. "Record Inductions - Appropriate Bodies" policy uses "AppropriateBodyUser" role
  # 2. "Register ECTs - Schools" policy uses "SchoolUser" role
  # 3. "Support - Internal" policy uses "DfEUser" role
  class Access
    # Additional admin roles do NOT need to be added here
    # @return [Array<String>]
    ROLES = %w[SchoolUser AppropriateBodyUser DfEUser].freeze

    attr_reader :user_id, :organisation_id

    def initialize(user_id:, organisation_id:)
      @user_id = user_id
      @organisation_id = organisation_id
    end

    # 1.SchoolUser
    # 2.AppropriateBodyUser
    # 3.SchoolUser and AppropriateBodyUser (school induction tutor or internal user)
    # 4.DfEUser
    #
    # @return [Array<String>]
    def roles
      access_level.roles.map(&:code)
    end

  private

    # @see https://github.com/DFE-Digital/login.dfe.public-api
    # @return [DfESignIn::AccessLevel]
    def access_level
      @access_level ||= DfESignIn::APIClient.new.access_levels(organisation_id:, user_id:)
    end
  end
end
