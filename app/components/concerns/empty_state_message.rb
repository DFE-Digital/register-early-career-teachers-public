module EmptyStateMessage
  extend ActiveSupport::Concern

private

  def empty_state_message
    base_message = "No #{status} inductions found"

    query.present? ? message_with_query(base_message) : "#{base_message}."
  end

  def message_with_query(base_message)
    "#{base_message} matching \"#{highlighted_query}\".".html_safe
  end

  def highlighted_query
    tag.strong(query, class: 'govuk-!-font-weight-bold')
  end
end
