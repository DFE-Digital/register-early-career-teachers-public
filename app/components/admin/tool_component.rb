module Admin
  class ToolComponent < ApplicationComponent
    erb_template <<~ERB
      <h2 class="govuk-heading-m">
        <%= govuk_link_to(name, href, no_visited_state: true, no_underline: true) %>
      </h2>
      <p class="govuk-body"><%= content %></p>
    ERB

    attr_reader :name, :href

    def initialize(name:, href:)
      @name = name
      @href = href
    end
  end
end
