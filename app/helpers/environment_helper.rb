module EnvironmentHelper
  FEEDBACK_SURVEY_FORM_URL = "https://forms.office.com/e/yrtkdGGKNu"

  def environment_specific_header_colour_class
    return if ENVIRONMENT_COLOUR.blank?

    "app-header--#{ENVIRONMENT_COLOUR}"
  end

  def environment_specific_phase_banner(html_attributes: {}, tag_html_attributes: {})
    tag_text = ENVIRONMENT_PHASE_BANNER_TAG || "Beta"
    banner_text = ENVIRONMENT_PHASE_BANNER_CONTENT || environment_phase_banner_default_content

    govuk_phase_banner(text: banner_text, tag: { text: tag_text, colour: ENVIRONMENT_COLOUR, html_attributes: tag_html_attributes }.compact, html_attributes:)
  end

private

  def environment_phase_banner_default_content
    "This is a new service – your #{support_feedback_form_link} will help us to improve it.".html_safe
  end

  def support_feedback_form_link
    govuk_link_to("feedback", FEEDBACK_SURVEY_FORM_URL)
  end
end
