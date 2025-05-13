module ProgrammeHelper
  def programme_type_name(programme_type)
    ::PROGRAMME_TYPES.fetch(programme_type&.to_sym, 'Programme type is not recognised')
  end

  def training_programme_for(trn)
    teacher = Teacher.find_by(trn:)
    return if teacher.blank?

    programme_type = ECTAtSchoolPeriod.latest_for_teacher(teacher).pick(:programme_type)
    return if programme_type.blank?

    programme_type_name(programme_type)
  end
end
