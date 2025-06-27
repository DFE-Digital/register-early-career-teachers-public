module ApplicationHelper
  include Pagy::Frontend

  def page_data(title:, header: :use_title, header_size: "l", error: false, backlink_href: nil, caption: nil, caption_size: 'm', header_classes: [])
    page_title = title_with_error_prefix(title, error:)
    content_for(:page_title) { page_title }

    backlink_or_breadcrumb = govuk_back_link(href: backlink_href) unless backlink_href.nil?
    content_for(:backlink_or_breadcrumb) { backlink_or_breadcrumb }

    if (page_header_text = (header == :use_title) ? title : header)
      page_header = tag.h1(page_header_text, class: ["govuk-heading-#{header_size}", *header_classes])
      content_for(:page_header) { page_header }

      page_caption = tag.span(caption, class: "govuk-caption-#{caption_size}")
      content_for(:page_caption) { page_caption } unless caption.nil?
    end
  end

  def backlink_with_fallback(fallback:)
    if request.referer.present? && request.referer != request.url
      request.referer
    else
      fallback
    end
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

  def boolean_to_yes_or_no(value)
    value ? "Yes" : "No"
  end

  def govuk_html_element(&block)
    tag.html(lang: 'en', class: %w[govuk-template govuk-template--rebranded], &block)
  end
end
