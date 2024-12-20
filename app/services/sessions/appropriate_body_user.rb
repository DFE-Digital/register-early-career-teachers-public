module Sessions
  class AppropriateBodyUser < SessionUser
    PROVIDER = :dfe_sign_in

    attr_reader :appropriate_body_id, :dfe_sign_in_organisation_id, :name

    def initialize(email:, name:, dfe_sign_in_organisation_id:, **)
      @name = name
      AppropriateBody.find_by!(dfe_sign_in_organisation_id:).then do |appropriate_body|
        @appropriate_body_id = appropriate_body.id
        @dfe_sign_in_organisation_id = dfe_sign_in_organisation_id
      end

      super(email:, **)
    end

    def appropriate_body_user? = true

    def to_h
      {
        "type" => self.class.name,
        "email" => email,
        "name" => name,
        "last_active_at" => last_active_at,
        "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id
      }
    end
  end
end
