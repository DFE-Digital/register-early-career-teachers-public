module Sessions
  class SchoolUser < SessionUser
    PROVIDER = :dfe_sign_in

    attr_reader :name, :school_urn, :dfe_sign_in_organisation_id

    def initialize(email:, name:, school_urn:, dfe_sign_in_organisation_id:, **)
      @name = name
      @school_urn = School.find_by!(urn: school_urn).urn
      @dfe_sign_in_organisation_id = dfe_sign_in_organisation_id

      super(email:, **)
    end

    def school_user? = true

    def to_h
      {
        "type" => self.class.name,
        "email" => email,
        "name" => name,
        "last_active_at" => last_active_at,
        "school_urn" => school_urn,
        "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id
      }
    end
  end
end
