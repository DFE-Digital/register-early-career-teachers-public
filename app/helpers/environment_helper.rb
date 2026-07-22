module EnvironmentHelper
  FEEDBACK_SURVEY_FORM_URL = "https://forms.office.com/e/yrtkdGGKNu"

  def environment_specific_header_colour_class
    return if ENVIRONMENT_COLOUR.blank?

    "app-header--#{ENVIRONMENT_COLOUR}"
  end

  def environment_specific_phase_banner_arguments(inverse: false)
    tag_text = ENVIRONMENT_PHASE_BANNER_TAG || "Beta"
    banner_text = ENVIRONMENT_PHASE_BANNER_CONTENT || environment_phase_banner_default_content

    banner_classes = class_names("govuk-width-container", "x-govuk-phase-banner--inverse" => inverse)
    tag_classes = class_names("x-govuk-tag--inverse" => inverse)

    {
      text: banner_text,
      tag: { text: tag_text, colour: ENVIRONMENT_COLOUR, html_attributes: { class: tag_classes } }.compact,
      html_attributes: { class: banner_classes },
    }
  end

private

  def environment_phase_banner_default_content
    "This is a new service – your #{support_feedback_form_link} will help us to improve it.".html_safe
  end

  def support_feedback_form_link
    govuk_link_to("feedback", FEEDBACK_SURVEY_FORM_URL)
  end
end
