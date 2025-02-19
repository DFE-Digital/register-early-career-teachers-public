module Sessions
  module Users
    class DfEPersona < User
      class DfEPersonaDisabledError < StandardError; end
      class UnknownUserEmail < StandardError; end

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

      def event_author_params
        {
          author_email: email,
          author_id: id,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = "Department for Education"

      def sign_out_path = '/sign-out'

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "last_active_at" => last_active_at
        }
      end

    private

      def user_from(email)
        ::User.find_by(email: email.downcase).tap do |user|
          raise(UnknownUserEmail, email) unless user
        end
      end
    end
  end
end
