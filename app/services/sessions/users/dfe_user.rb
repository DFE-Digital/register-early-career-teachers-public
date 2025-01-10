module Sessions
  module Users
    class DfEUser < User
      USER_TYPE = :dfe_staff_user
      PROVIDER = :otp

      attr_reader :id, :name

      def initialize(email:, **)
        ::User.find_by!(email:).then do |user|
          @dfe_user = user.dfe_user?
          @id = user.id
          @name = user.name
        end

        super(email:, **)
      end

      def dfe_user? = @dfe_user

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "last_active_at" => last_active_at
        }
      end

      def event_author_params
        {
          author_email: email,
          author_id: id,
          author_name: name,
          author_type: USER_TYPE,
        }
      end
    end
  end
end
