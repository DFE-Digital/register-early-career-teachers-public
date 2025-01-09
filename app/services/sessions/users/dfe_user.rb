module Sessions
  module Users
    class DfEUser < User
      USER_TYPE = :dfe_staff_user
      PROVIDER = :otp

      attr_reader :id, :name

      def initialize(email:, **)
        ::User.find_by!(email:).then do |user|
          @id = user.id
          @name = user.name
        end

        super(email:, **)
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

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "last_active_at" => last_active_at
        }
      end
    end
  end
end
