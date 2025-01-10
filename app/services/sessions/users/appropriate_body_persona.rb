module Sessions
  module Users
    class AppropriateBodyPersona < User
      USER_TYPE = :appropriate_body_user
      PROVIDER = :persona

      attr_reader :appropriate_body_id, :name

      def initialize(email:, name:, appropriate_body_id:, **)
        @appropriate_body_id = AppropriateBody.find(appropriate_body_id).id
        @name = name

        super(email:, **)
      end

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "appropriate_body_id" => appropriate_body_id
        }
      end

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end
    end
  end
end
