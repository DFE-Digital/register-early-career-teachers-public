class TimelineComponent < ViewComponent::Base
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

  class ItemComponent < ViewComponent::Base
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
      tag.div(class: "app-timeline__description") { event.body }
    end

    def byline
      attribution = event.author_name || event.author&.name || event.author_type

      tag.p("by #{attribution}", class: "app-timeline__byline")
    end
  end
end
