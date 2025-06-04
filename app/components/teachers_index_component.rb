class TeachersIndexComponent < ViewComponent::Base
  include GovukLinkHelper
  include Pagy::Frontend
  include Rails.application.routes.url_helpers

  def initialize(appropriate_body:, teachers:, pagy:, status: 'open', query: nil)
    @appropriate_body = appropriate_body
    @teachers = teachers
    @pagy = pagy
    @status = normalize_status(status)
    @query = query
  end

private

  attr_reader :appropriate_body, :teachers, :pagy, :status, :query

  def normalize_status(status)
    return 'open' if status.blank?

    %w[open closed].include?(status) ? status : 'open'
  end

  def showing_closed?
    status == 'closed'
  end

  def bulk_upload_enabled?
    Rails.application.config.enable_bulk_upload
  end

  def teachers_present?
    teachers.any?
  end

  def search_label_text
    "Search for an #{status} induction by name or teacher reference number (TRN)"
  end

  def empty_state_message
    base_message = "No #{status} inductions found"

    if query.present?
      "#{base_message} matching \"<strong>#{query}</strong>\".".html_safe
    else
      "#{base_message}."
    end
  end

  def ects_service
    @ects_service ||= AppropriateBodies::ECTs.new(appropriate_body)
  end

  def open_count
    @open_count ||= ects_service.current.count
  end

  def closed_count
    @closed_count ||= ects_service.completed_while_at_appropriate_body.count
  end

  def current_count
    showing_closed? ? closed_count : open_count
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

  def search_form_url
    ab_teachers_path
  end
end
