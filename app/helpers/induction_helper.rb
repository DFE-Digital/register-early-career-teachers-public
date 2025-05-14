module InductionHelper
  def claiming_body?(teacher, body)
    return true if teacher.nil?

    Teachers::Induction.new(teacher).with_appropriate_body?(body)
  end
end
