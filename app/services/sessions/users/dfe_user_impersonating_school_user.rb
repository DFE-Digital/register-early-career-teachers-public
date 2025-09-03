module Sessions
  module Users
    class DfEUserImpersonatingSchoolUser < DfEUser
      class UnknownOrganisationURN < StandardError; end

      attr_reader :original_type, :school

      USER_TYPE = :dfe_user_impersonating_school_user

      def initialize(email:, school_urn:, original_type:, **)
        @user = user_from(email)
        @id = user.id
        @school = school_from(school_urn)
        @name = user.name
        @original_type = original_type

        super(email: user.email)
      end

      def dfe_user? = true
      def dfe_user_impersonating_school_user? = true
      def school_urn = @school.urn
      def school_user? = true

      def to_h
        {
          'type' => self.class.name,
          'email' => email,
          'school_urn' => school_urn,
          'last_active_at' => last_active_at,
          'original_type' => original_type.to_s
        }
      end

      def rebuild_original_session
        to_h.merge({ 'type' => original_type }).except('school_urn', 'original_type')
      end

    private

      def school_from(urn)
        ::School.find_by(urn:).tap do |school|
          raise(UnknownOrganisationURN, urn) unless school
        end
      end
    end
  end
end
