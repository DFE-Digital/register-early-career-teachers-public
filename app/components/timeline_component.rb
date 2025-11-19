class TimelineComponent < ApplicationComponent
  renders_many :items, "ItemComponent"

  attr_reader :events

  def initialize(events)
    events.each { |event| with_item(event) }
  end

  def call
    tag.div(class: "app-timeline") do
      safe_join(items)
    end
  end

  class ItemComponent < ApplicationComponent
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def call
      tag.div(class: "app-timeline__item") do
        safe_join([header, timestamp, description])
      end
    end

  private

    def header
      tag.div(class: "app-timeline__header") do
        safe_join([title, byline], " ")
      end
    end

    def title
      tag.h2(event.heading, class: "app-timeline__title")
    end

    def timestamp
      tag.p(class: "app-timeline__date") do
        tag.time(event.happened_at.to_fs(:govuk_short), datetime: event.happened_at.to_fs(:iso8601))
      end
    end

    def description
      tag.div(class: "app-timeline__description") do
        safe_join([information, modifications_list].compact_blank)
      end
    end

    def information
      return if event.body.blank? && event.zendesk_ticket_id.blank?

      zendesk_url = if event.zendesk_ticket_id.present?
                      govuk_link_to(
                        "Zendesk ticket",
                        zendesk_url(event.zendesk_ticket_id),
                        new_tab: true
                      )
                    end

      tag.p do
        safe_join([event.body, tag.br, zendesk_url].compact)
      end
    end

    # @param ticket_id [Integer] 6 digit Zendesk ticket ID
    # @return [String]
    def zendesk_url(ticket_id)
      "https://becomingateacher.zendesk.com/agent/tickets/#{ticket_id}"
    end

    def modifications_list
      return if event.modifications.blank?

      safe_join(
        [
          tag.h3("Changes", class: "govuk-heading-s"),
          govuk_list(event.modifications)
        ]
      )
    end

    def byline
      attribution = event.author_name || event.author&.name || event.author_type

      tag.p("by #{attribution}", class: "app-timeline__byline")
    end
  end
end
