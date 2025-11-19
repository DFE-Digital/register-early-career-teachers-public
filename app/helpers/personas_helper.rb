module PersonasHelper
  class UnrecognisedPersonaType < StandardError; end

  def persona_organisation(persona)
    case persona.type
    when "School user"
      "#{persona.school_name} (#{persona.school_type})"
    when "Appropriate body user"
      persona.appropriate_body_name
    when "DfE staff"
      role = User::ROLES.fetch(persona.role.to_sym)
      "Department for Education staff member (#{role})"
    else
      fail(UnrecognisedPersonaType)
    end
  end

  def persona_role(persona)
    return unless persona.type == "DfE staff"

    User::ROLES.fetch(persona.role.to_sym)
  end
end
