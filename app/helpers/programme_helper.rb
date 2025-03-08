module ProgrammeHelper
  def programme_type_name(programme_type)
    ::PROGRAMME_TYPES.fetch(programme_type&.to_sym, 'Programme type is not recognised')
  end
end
