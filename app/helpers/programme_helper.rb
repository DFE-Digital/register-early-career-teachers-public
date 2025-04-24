module ProgrammeHelper
  def programme_type_name(programme_type)
    ::PROGRAMME_TYPES.fetch(programme_type&.to_sym, 'Programme type is not recognised')
  end

  def programme_choices(use_previous_ect_choices)
    return "Yes, use the programme choices used by my school previously" if use_previous_ect_choices

    "No, don't use the programme choices used by my school previously"
  end
end
