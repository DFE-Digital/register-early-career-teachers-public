module Shared
  class TopSearchComponent < ViewComponent::Base
    attr_reader :query_param, :label_text, :submit_text, :url

    def initialize(
      query_param: :q,
      label_text: 'Search by name or teacher reference number (TRN)',
      submit_text: 'Search',
      url: nil
    )
      @query_param = query_param
      @label_text = label_text
      @submit_text = submit_text
      @url = url
    end

    def call
      form_with(method: :get, url: form_url, html: { class: "app-search-form" }) do |f|
        safe_join([
          content_tag(:div, class: "govuk-form-group") do
            f.govuk_text_field(
              query_param,
              value: search_value,
              label: { text: label_text, size: "s" }
            )
          end,
          f.govuk_submit(submit_text, class: "govuk-button--secondary app-search__button")
        ])
      end
    end

  private

    def form_url
      url || request.path
    end

    def search_value
      params[query_param].to_s
    end
  end
end
