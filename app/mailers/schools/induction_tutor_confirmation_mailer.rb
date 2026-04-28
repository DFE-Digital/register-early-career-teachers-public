class Schools::InductionTutorConfirmationMailer < ApplicationMailer
  SUBJECT_PREFIX = "You are the induction tutor for"
  SETUP_ECTE_GUIDANCE_URL = "https://www.gov.uk/guidance/set-up-and-manage-the-early-career-teacher-entitlement"
  REGISTER_ECT_SERVICE_URL = "https://www.register-early-career-teachers.education.gov.uk/"
  DFE_SIGN_IN_URL = "https://services.signin.education.gov.uk/"
  DFE_SIGN_IN_HELP_URL = "https://help.signin.education.gov.uk/contact-us"
  ECT_GUIDANCE_COLLECTION_URL = "https://www.gov.uk/government/collections/induction-training-and-support-for-early-career-teachers-ects"

  def confirmation
    school = params.fetch(:school)

    prepare_personalisation(school)
    view_mail(NOTIFY_TEMPLATE_ID, to: school.induction_tutor_email, subject: subject_line(school.name))
  end

private

  def prepare_personalisation(school)
    @school_name = school.name
    @induction_tutor_name = school.induction_tutor_name
    @teacher_entitlement_url = SETUP_ECTE_GUIDANCE_URL
    @privacy_notice_url = PRIVACY_NOTICE_URL
    @service_url = REGISTER_ECT_SERVICE_URL
    @dfe_sign_in_url = DFE_SIGN_IN_URL
    @dfe_sign_in_help_url = DFE_SIGN_IN_HELP_URL
    @help_with_ect_url = ECT_GUIDANCE_COLLECTION_URL
  end

  def subject_line(school_name)
    "#{SUBJECT_PREFIX} #{school_name}"
  end
end
