module Sessions
  class SchoolPersona < SessionUser
    PROVIDER = :persona

    attr_reader :name, :school_urn

    def initialize(email:, name:, school_urn:, **)
      @name = name
      @school_urn = School.find_by!(urn: school_urn).urn
      super(email:, **)
    end

    def school_user? = true

    def to_h
      {
        "type" => self.class.name,
        "email" => email,
        "name" => name,
        "last_active_at" => last_active_at,
        "school_urn" => school_urn.presence,
      }
    end
  end
end
