module Navigation
  class SecondaryNavigationComponent < ApplicationComponent
    attr_accessor :items, :labelled_by, :visually_hidden_title, :html_classes, :html_attributes

    def initialize(items:, labelled_by: nil, visually_hidden_title: "Secondary Menu", classes: nil, attributes: {})
      @items = items
      @labelled_by = labelled_by
      @visually_hidden_title = visually_hidden_title
      @html_classes = classes
      @html_attributes = attributes
    end

    def render?
      items.present?
    end

    def navigation_classes
      class_names("x-govuk-secondary-navigation", html_classes)
    end

    def navigation_attributes
      base_attributes = {
        "aria-label" => labelled_by.present? ? nil : visually_hidden_title,
        "aria-labelledby" => labelled_by
      }.compact

      base_attributes.merge(html_attributes)
    end

    def item_classes(item)
      base_classes = %w[
        x-govuk-secondary-navigation__list-item
      ]

      base_classes << "x-govuk-secondary-navigation__list-item--current" if item[:current]
      base_classes << item[:classes] if item[:classes].present?

      base_classes.join(" ")
    end

    def link_attributes(item)
      attributes = {
        class: "x-govuk-secondary-navigation__link",
        href: item[:href]
      }

      attributes["aria-current"] = "page" if item[:current]

      attributes
    end
  end
end
