class ApplicationMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "c437a1cb-9e1c-49ff-83ee-967c92f95637"
  PRIVACY_NOTICE_URL = "https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers"

private

  # Bypass GOV.UK Notify in development when the API key is not configured,
  # allowing mailer previews to render locally without a Notify account.
  def view_mail(template_id, options)
    return mail(options) if development_without_notify_api_key?

    super
  end

  def development_without_notify_api_key?
    Rails.env.development? && !ENV.key?("GOVUK_NOTIFY_API_KEY")
  end
end
