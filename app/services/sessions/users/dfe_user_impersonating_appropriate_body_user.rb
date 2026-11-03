module Sessions
  module Users
    class DfEUserImpersonatingAppropriateBodyUser < DfEUser
      class UnknownOrganisationId < Sessions::User::InvalidSession; end

      include Fingerprint

      attr_reader :original_type, :appropriate_body_period

      USER_TYPE = :dfe_user_impersonating_appropriate_body_user

      alias_method :dfe_analytics_user_id, :id

      def initialize(email:, appropriate_body_period_id:, original_type:, **)
        @user = user_from(email)
        @id = user.id
        @appropriate_body_period = appropriate_body_period_from(appropriate_body_period_id)
        @name = user.name
        @original_type = original_type

        super(email: user.email)
      end

      delegate :id, to: :appropriate_body_period, prefix: true, allow_nil: true

      def dfe_user? = false
      def dfe_user_impersonating_appropriate_body_user? = true
      def appropriate_body_user? = true

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "appropriate_body_period_id" => appropriate_body_period.id,
          "last_active_at" => last_active_at,
          "original_type" => original_type.to_s
        }
      end

      def rebuild_original_session
        to_h.merge({ "type" => original_type }).except("appropriate_body_period_id", "original_type")
      end

    private

      def appropriate_body_period_from(id)
        ::AppropriateBodyPeriod.find_by(id:).tap do |appropriate_body_period|
          raise(UnknownOrganisationId, id) unless appropriate_body_period
        end
      end
    end
  end
end
