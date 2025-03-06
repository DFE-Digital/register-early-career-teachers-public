module ApplicationHelper
  include Pagy::Frontend

  def page_data(title:, header: nil, header_size: "l", error: false, backlink_href: nil, caption: nil, caption_size: 'm')
    page_title = title_with_error_prefix(title, error:)

    content_for(:page_title) { page_title }

    return { page_title: } if header == false

    backlink_or_breadcrumb = govuk_back_link(href: backlink_href) unless backlink_href.nil?

    content_for(:backlink_or_breadcrumb) { backlink_or_breadcrumb }

    page_header = tag.h1(header || title, class: "govuk-heading-#{header_size}")

    content_for(:page_header) { page_header }

    page_caption = tag.span(caption, class: "govuk-caption-#{caption_size}")

    content_for(:page_caption) { page_caption } unless caption.nil?

    { page_title:, backlink_or_breadcrumb:, page_header:, page_caption: }
  end

  def page_data_from_front_matter(yaml)
    parsed_yaml = YAML.load(yaml)&.symbolize_keys

    return unless parsed_yaml

    page_data(**parsed_yaml)
  end

  def support_mailto_link(text = Rails.application.config.support_email_address)
    govuk_link_to(text, 'mailto:' + Rails.application.config.support_email_address)
  end

  def ruby_pants_options
    {
      double_left_quote: '“',
      double_right_quote: '”',
      single_left_quote: '‘',
      single_right_quote: '’',
    }
  end

  def smart_quotes(string)
    return string if string.blank?

    RubyPants.new(string, %i[quotes], ruby_pants_options).to_html
  end
end
