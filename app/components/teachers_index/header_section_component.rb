module TeachersIndex
  class HeaderSectionComponent < ViewComponent::Base
    include GovukLinkHelper
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TextHelper

    def initialize(status:, current_count:, open_count:, closed_count:)
      @status = status
      @current_count = current_count
      @open_count = open_count
      @closed_count = closed_count
    end

  private

    attr_reader :status, :current_count, :open_count, :closed_count

    def heading_text
      pluralize(current_count, "#{status} induction")
    end

    def showing_closed?
      status == 'closed'
    end

    def should_show_navigation_link?
      return true if showing_closed?

      closed_count.positive?
    end

    def navigation_link_text
      if showing_closed?
        "View open inductions (#{open_count})"
      else
        "View closed inductions (#{closed_count})"
      end
    end

    def navigation_link_path
      if showing_closed?
        ab_teachers_path
      else
        ab_teachers_path(status: 'closed')
      end
    end
  end
end
