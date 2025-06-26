module Shared
  class PaginationSummaryComponent < ViewComponent::Base
    attr_reader :pagy, :record_name

    def initialize(pagy:, record_name: "records")
      @pagy = pagy
      @record_name = record_name
    end

    delegate :from, :to, :count,
             to: :pagy

    def summary_text
      "Showing #{from} to #{to} of #{count} #{record_name}"
    end
  end
end
