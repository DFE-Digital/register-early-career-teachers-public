module InductionHelper
  def claiming_body?(teacher, body)
    return true if teacher.nil?

    Teachers::Induction.new(teacher).with_appropriate_body?(body)
  end

  def induction_start_date_for(trn)
    InductionPeriod.where(teacher: Teacher.find_by(trn:)).order(:started_on).limit(1).pick(:started_on)&.to_fs(:govuk)
  end
end
