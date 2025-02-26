module TeacherHelper
  # @param teacher [Teacher]
  def teacher_full_name(teacher)
    ::Teachers::Name.new(teacher).full_name
  end

  # @param teacher [Teacher]
  def teacher_trn(teacher)
    "TRN: #{teacher.trn}"
  end

  def teacher_date_of_birth_hint_text
    "For example, 20 4 2001"
  end

  def teacher_induction_date_hint_text
    "For example, 20 4 #{Date.current.year.pred}"
  end
end
