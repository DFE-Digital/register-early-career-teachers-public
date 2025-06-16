class TeachersIndexComponent < ViewComponent::Base
  include GovukLinkHelper
  include Rails.application.routes.url_helpers

  renders_one :bulk_upload_links, -> {
    TeachersIndex::BulkUploadLinksComponent.new(appropriate_body:)
  }

  renders_one :header, -> {
    TeachersIndex::HeaderSectionComponent.new(
      status:,
      current_count:,
      open_count:,
      closed_count:,
      query:
    )
  }

  renders_one :search_box, -> {
    TeachersIndex::SearchSectionComponent.new(status:, query:)
  }

  renders_one :table, -> {
    TeachersIndex::TableSectionComponent.new(
      teachers:,
      pagy:,
      status:,
      query:
    )
  }

  attr_reader :appropriate_body, :teachers, :pagy, :status, :query

  def initialize(appropriate_body:, teachers:, pagy:, status: 'open', query: nil)
    @appropriate_body = appropriate_body
    @teachers = teachers
    @pagy = pagy
    @status = normalize_status(status)
    @query = query
  end

private

  def before_render
    with_bulk_upload_links
    with_header
    with_search_box
    with_table
  end

  def normalize_status(status)
    return 'open' if status.blank?

    %w[open closed].include?(status) ? status : 'open'
  end

  def showing_closed?
    status == 'closed'
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

  # Return filtered counts when searching, total counts when not searching
  def open_count
    if query.present?
      filtered_open_count
    else
      @open_count ||= ects_service.current.count
    end
  end

  def closed_count
    if query.present?
      filtered_closed_count
    else
      @closed_count ||= ects_service.completed_while_at_appropriate_body.count
    end
  end

  # Return filtered count when searching, total count when not searching
  def current_count
    if query.present?
      pagy.count
    else
      showing_closed? ? closed_count : open_count
    end
  end

  def filtered_open_count
    @filtered_open_count ||= Teachers::Search.new(
      query_string: query,
      appropriate_bodies: appropriate_body,
      status: 'open'
    ).count
  end

  def filtered_closed_count
    @filtered_closed_count ||= Teachers::Search.new(
      query_string: query,
      appropriate_bodies: appropriate_body,
      status: 'closed'
    ).count
  end
end
