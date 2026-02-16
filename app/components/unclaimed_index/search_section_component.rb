module UnclaimedIndex
  class SearchSectionComponent < ApplicationComponent
    def initialize(query:, form_url:)
      @query = query
      @form_url = form_url
    end

  private

    attr_reader :query, :form_url
  end
end
