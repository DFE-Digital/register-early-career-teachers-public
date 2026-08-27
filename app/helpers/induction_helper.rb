module InductionHelper
  def claiming_body?(teacher, body)
    return true if teacher.nil?

    Induction::TeacherInformation.new(teacher).with_appropriate_body?(body)
  end
end
