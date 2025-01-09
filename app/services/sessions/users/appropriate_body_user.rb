module Sessions
  module Users
    class AppropriateBodyUser < User
      USER_TYPE = :appropriate_body_user
      PROVIDER = :dfe_sign_in

      attr_reader :appropriate_body, :dfe_sign_in_organisation_id, :dfe_sign_in_user_id, :name

      def initialize(email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, **)
        @name = name
        @appropriate_body = AppropriateBody.find_by!(dfe_sign_in_organisation_id:)
        @dfe_sign_in_organisation_id = dfe_sign_in_organisation_id
        @dfe_sign_in_user_id = dfe_sign_in_user_id

        super(email:, **)
      end

      delegate :id, to: :appropriate_body, prefix: true, allow_nil: true
      def dfe_sign_in_authorisable? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = appropriate_body.name

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id,
          "dfe_sign_in_user_id" => dfe_sign_in_user_id
        }
      end
    end
  end
end
