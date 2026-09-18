module Admin::DataFixes
  class ProcessedChangesComponent < ApplicationComponent
    def initialize(changes)
      @changes = changes
    end

    def render? = @changes&.any?

    erb_template <<~ERB
      <% @changes.each do |change| %>
        <%= govuk_summary_card(title: change["gid"], classes: "data-fixes") do %>
          <%= govuk_summary_list do |summary_list| %>
            <%= summary_list.with_row do |row| %>
              <%= row.with_key { "Action" } %>
              <%= row.with_value { change["action"] } %>
            <% end %>

            <% change["changes"].each do |attribute, values| %>
              <%= summary_list.with_row do |row| %>
                <%= row.with_key { attribute } %>
                <%= row.with_value do %>
                  <del><%= value_to_display(values.first) %></del>
                  <br>
                  <ins><%= value_to_display(values.last) %></ins>
                <% end %>
              <% end %>
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    ERB

  private

    def value_to_display(value)
      case
      when value == false
        "false"
      when value == true
        "true"
      when value.blank?
        "Nil"
      else
        value
      end
    end
  end
end
