class TimeTravellerComponent < ApplicationComponent
  erb_template <<~ERB
    <% if Current.date_after_time_travel.present? %>
      <%= govuk_phase_banner(tag: {colour: "purple", text: "Warning 📆🚨"}) do %>
        <%= message %>
        <%= govuk_link_to("Change it or reset it", new_time_traveller_path) %>
      <% end %>
    <% else %>
      <%= govuk_phase_banner(tag: {colour: "purple", text: "Travel in time ⏪"}) do %>
        <%= govuk_link_to("Choose a date", new_time_traveller_path) %>
      <% end %>
    <% end %>
  ERB

  def render? = Rails.application.config.enable_time_travel

private

  def message
    <<~TXT.squish
      Today is #{Current.date_after_time_travel.to_fs(:govuk)}, which is
      #{relative_date_in_words}!
    TXT
  end

  def relative_date_in_words
    distance_in_words = helpers.distance_of_time_in_words(
      Current.date_before_time_travel,
      Current.date_after_time_travel
    )
    suffix = if Current.date_after_time_travel.after?(Current.date_before_time_travel)
               "from now"
             else
               "ago"
             end

    "#{distance_in_words} #{suffix}"
  end
end
