class Schools::ECTRegistrationMailer < ApplicationMailer
  SUBJECT = "You’ve been registered for early career teacher training and support"
  ECT_GUIDANCE_URL = "https://www.gov.uk/government/publications/early-career-teachers-your-training-and-support-entitlement"

  def school_led_confirmation
    ect_at_school_period = params.fetch(:ect_at_school_period)

    prepare_personalisation(ect_at_school_period)
    view_mail(NOTIFY_TEMPLATE_ID, to: ect_at_school_period.email, subject: SUBJECT)
  end

  def provider_led_confirmation
    ect_at_school_period = params.fetch(:ect_at_school_period)

    prepare_personalisation(ect_at_school_period)
    view_mail(NOTIFY_TEMPLATE_ID, to: ect_at_school_period.email, subject: SUBJECT)
  end

private

  def prepare_personalisation(ect_at_school_period)
    @early_career_teacher_name = Teachers::Name.new(ect_at_school_period.teacher).full_name
    @school_name = ect_at_school_period.school.name
    @ect_guidance_url = ECT_GUIDANCE_URL
    @privacy_notice_url = PRIVACY_NOTICE_URL
  end
end
