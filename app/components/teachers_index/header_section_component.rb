module TeachersIndex
  class HeaderSectionComponent < ViewComponent::Base
    include GovukLinkHelper
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TextHelper

    def initialize(status:, current_count:, open_count:, closed_count:, query: nil)
      @status = status
      @current_count = current_count
      @open_count = open_count
      @closed_count = closed_count
      @query = query
    end

  private

    attr_reader :status, :current_count, :open_count, :closed_count, :query

    def heading_text
      if current_count.zero? && query.present?
        "No #{status} inductions for \"#{query}\""
      else
        pluralize(current_count, "#{status} induction")
      end
    end

    def showing_closed?
      status == 'closed'
    end

    def should_show_navigation_link?
      navigation_count.positive?
    end

    def navigation_count
      showing_closed? ? open_count : closed_count
    end

    def navigation_link_text
      target_status = showing_closed? ? "open" : "closed"

      if navigation_count.positive?
        "View #{target_status} inductions (#{navigation_count})"
      else
        "No #{target_status} inductions"
      end
    end

    def navigation_link_path
      if showing_closed?
        open_ab_teachers_path(q: query)
      else
        closed_ab_teachers_path(q: query)
      end
    end
  end
end
