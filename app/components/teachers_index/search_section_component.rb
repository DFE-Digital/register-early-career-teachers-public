module TeachersIndex
  class SearchSectionComponent < ViewComponent::Base
    include Rails.application.routes.url_helpers

    def initialize(status:, query:)
      @status = status
      @query = query
    end

  private

    attr_reader :status, :query

    def search_label_text
      "Search for an #{status} induction by name or teacher reference number (TRN)"
    end
  end
end
