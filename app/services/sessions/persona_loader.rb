module Sessions
  class PersonaLoader
    attr_reader :filename

    PersonaData = Struct.new(
      :name,
      :user_id,
      :email,
      :school_urn,
      :school_name,
      :school_type,
      :image,
      :alt,
      :appropriate_body_period_id,
      :appropriate_body_name,
      :dfe_staff,
      :type,
      :role
    )

    def initialize(filename = "config/personas.yml")
      @filename = filename
    end

    def personas
      personas_yaml.map do |persona|
        PersonaData.new(
          **persona.symbolize_keys,
          school_urn: schools[persona["school_name"]]&.urn,
          appropriate_body_period_id: appropriate_bodies[persona["appropriate_body_name"]]&.id,
          user_id: users[persona["name"]]&.id
        )
      end
    end

  private

    def personas_yaml
      @personas_yaml ||= YAML.load_file(Rails.root.join(@filename))
    end

    def schools
      @schools ||= School.includes(:gias_school)
                         .where(gias_school: { name: school_names })
                         .index_by(&:name)
    end

    def school_names
      personas_yaml.map { it["school_name"] }.compact
    end

    def appropriate_bodies
      @appropriate_bodies ||= AppropriateBodyPeriod.where(name: appropriate_body_names)
                                                   .index_by(&:name)
    end

    def appropriate_body_names
      personas_yaml.map { it["appropriate_body_name"] }.compact
    end

    def users
      @users ||= ::User.where(name: user_names).index_by(&:name)
    end

    def user_names
      personas_yaml.select { it["dfe_staff"] }.map { it["name"] }.compact
    end
  end
end
