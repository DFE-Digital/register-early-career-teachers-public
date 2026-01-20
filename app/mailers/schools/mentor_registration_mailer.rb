class Schools::MentorRegistrationMailer < ApplicationMailer
  SUBJECT_PREFIX = "You’ve been registered as a mentor for early career teachers at"
  MENTORS_GUIDANCE_URL = "https://www.gov.uk/government/publications/early-career-teacher-entitlement-roles-and-responsibilities/mentors-responsibilities-for-early-career-teacher-entitlement"

  def confirmation
    mentor_at_school_period = params.fetch(:mentor_at_school_period)

    prepare_personalisation(mentor_at_school_period)
    view_mail(NOTIFY_TEMPLATE_ID, to: mentor_at_school_period.email, subject: subject_line)
  end

private

  def prepare_personalisation(mentor_at_school_period)
    @mentor_name = Teachers::Name.new(mentor_at_school_period.teacher).full_name
    @school_name = mentor_at_school_period.school.name
    @mentors_guidance_url = MENTORS_GUIDANCE_URL
    @privacy_notice_url = PRIVACY_NOTICE_URL
  end

  def subject_line
    "#{SUBJECT_PREFIX} #{@school_name}"
  end
end
