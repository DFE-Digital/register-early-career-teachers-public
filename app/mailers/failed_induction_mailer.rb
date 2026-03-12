class FailedInductionMailer < ApplicationMailer
  TRA_EMAIL = "TRA.SE@education.gov.uk"

  def tra_notification(induction_period:)
    teacher = induction_period.teacher
    @teacher_name = Teachers::Name.new(teacher).full_name
    @trn = teacher.trn
    @appropriate_body_name = induction_period.appropriate_body_name
    @fail_confirmation_sent_on = induction_period.fail_confirmation_sent_on.to_fs(:govuk)

    view_mail(NOTIFY_TEMPLATE_ID, to: TRA_EMAIL, subject: "Fail notification from RIAB")
  end
end
