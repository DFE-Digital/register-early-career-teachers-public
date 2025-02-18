module EnvironmentHelper
  def environment_specific_header_colour_class
    return if ENVIRONMENT_COLOUR.blank?

    "app-header--#{ENVIRONMENT_COLOUR}"
  end

  def environment_specific_phase_banner
    tag_text = ENVIRONMENT_PHASE_BANNER_TAG || "Beta"
    banner_text = ENVIRONMENT_PHASE_BANNER_CONTENT || environment_phase_banner_default_content

    govuk_phase_banner(text: banner_text, tag: { text: tag_text, colour: ENVIRONMENT_COLOUR }.compact)
  end

private

  def environment_phase_banner_default_content
    "This is a new service – your #{support_mailto_link('feedback')} will help us to improve it.".html_safe
  end
end
