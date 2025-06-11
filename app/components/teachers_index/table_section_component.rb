module TeachersIndex
  class TableSectionComponent < ViewComponent::Base
    include GovukLinkHelper
    include Pagy::Frontend
    include Rails.application.routes.url_helpers

    def initialize(teachers:, pagy:, status:, query:)
      @teachers = teachers
      @pagy = pagy
      @status = status
      @query = query
    end

  private

    attr_reader :teachers, :pagy, :status, :query

    def teachers_present?
      teachers.any?
    end

    def empty_state_message
      base_message = "No #{status} inductions found"

      if query.present?
        "#{base_message} matching \"<strong>#{query}</strong>\".".html_safe
      else
        "#{base_message}."
      end
    end
  end
end
