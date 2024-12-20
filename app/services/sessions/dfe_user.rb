module Sessions
  class DfEUser < SessionUser
    PROVIDER = :otp

    attr_reader :name

    def initialize(email:, **)
      User.find_by!(email:).then do |user|
        @dfe_user = user.dfe_user?
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
  end
end
