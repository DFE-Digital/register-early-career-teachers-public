class TimeTravellerComponent < ApplicationComponent
  def initialize(time_travelled_date:)
    @time_travelled_date = Date.parse(time_travelled_date)
  rescue TypeError, ArgumentError
    @time_travelled_date = nil
  end

  erb_template <<~ERB
    <% if @time_travelled_date.present? %>
      <%= govuk_phase_banner(tag: {colour: "purple", text: "Warning 📆🚨"}) do %>
        <%= message %>
        <%= govuk_link_to("Change it", new_time_traveller_path) %>,
      <% end %>
    <% else %>
      <%= govuk_phase_banner(tag: {colour: "purple", text: "Travel in time ⏪"}) do %>
        <%= govuk_link_to("Choose a date", new_time_traveller_path) %>
      <% end %>
    <% end %>
  ERB

private

  attr_reader :time_travelled_date

  def message
    <<~TXT.squish
      Today is #{time_travelled_date.to_fs(:govuk)}, which is
      #{helpers.relative_time_in_words(time_travelled_date)}!
    TXT
  end
end
