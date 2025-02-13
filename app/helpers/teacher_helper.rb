module TeacherHelper
  # TODO: this helper could get used loads
  # @param teacher [Teacher]
  def teacher_full_name(teacher)
    ::Teachers::Name.new(teacher).full_name
  end
end
