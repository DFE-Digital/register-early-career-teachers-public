module Shared
  class PaginationSummaryComponent < ViewComponent::Base
    attr_reader :pagy, :record_name

    def initialize(pagy:, record_name: "records")
      @pagy = pagy
      @record_name = record_name
    end

    delegate :from, :to, :count,
             to: :pagy

    def render?
      pagy.pages > 1
    end

    def summary_text
      "Showing #{tag.strong from} to #{tag.strong to} of #{tag.strong count} #{record_name}".html_safe
    end
  end
end
