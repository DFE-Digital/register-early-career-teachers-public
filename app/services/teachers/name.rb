class Teachers::Name
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  def full_name
    return if teacher.blank?

    teacher.corrected_name.presence || full_name_in_trs
  end

  def full_name_in_trs
    return if teacher.blank?

    %(#{teacher.first_name} #{teacher.last_name})
  end
end
