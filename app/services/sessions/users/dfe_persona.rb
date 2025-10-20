module Sessions
  module Users
    class DfEPersona < User
      class DfEPersonaDisabledError < StandardError; end
      class UnknownUserEmail < StandardError; end

      include Sessions::ImpersonateSchoolUser

      USER_TYPE = :dfe_staff_user
      PROVIDER = :persona

      attr_reader :id, :name, :user

      def initialize(email:, **)
        fail DfEPersonaDisabledError unless Rails.application.config.enable_personas

        @user = user_from(email)
        @id = user.id
        @name = user.name

        super(email: user.email, **)
      end

      delegate :role, :admin?, :super_admin?, :finance?, to: :user

      def dfe_user? = true

      def event_author_params
        {
          author_email: email,
          author_id: id,
          author_name: name,
          author_type: USER_TYPE
        }
      end

      def organisation_name = "Department for Education"

      # @return [Hash] session data
      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "last_active_at" => last_active_at
        }
      end

      private

      def user_from(email)
        ::User.find_by(email:).tap do |user|
          raise(UnknownUserEmail, email) unless user
        end
      end
    end
  end
end
