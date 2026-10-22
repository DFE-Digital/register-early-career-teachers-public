module Sessions
  module DfESignIn
    class OrganisationDetails
      def initialize(details)
        @details = details.presence || {}
      end

      def missing? = details.empty?
      def access_requestable? = !missing? && role_ids.any?

      def name = details["dfe_sign_in_organisation_name"]
      def organisation_id = details["dfe_sign_in_organisation_id"]
      def user_id = details["dfe_sign_in_user_id"]

      def role_ids = @role_ids ||= roles.pluck(:dfe_sign_in_role_id)

    private

      attr_reader :details

      def urn = details["dfe_sign_in_organisation_urn"]

      def roles = DfESignInRole.where(code: role_codes)

      def role_codes = [
        ("school_user" if school_user?),
        ("appropriate_body_user" if appropriate_body_user?)
      ].compact

      def school_user? = School.exists?(urn:)

      def appropriate_body_user?
        AppropriateBodyPeriod.exists?(dfe_sign_in_organisation_id: organisation_id)
      end
    end
  end
end
