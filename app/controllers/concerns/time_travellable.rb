require "active_support/testing/time_helpers"

module TimeTravellable
  extend ActiveSupport::Concern
  include ActiveSupport::Testing::TimeHelpers

  included do
    around_action :travel_in_time,
                  if: -> { Rails.application.config.enable_time_travel }
  end

private

  def travel_in_time
    if session["date_after_time_travel"].present?
      Rails.logger.info("[Time travel] Preparing travel to #{session['date_after_time_travel']}")
      Current.date_before_time_travel = Date.current
      Current.date_after_time_travel = Date.parse(session["date_after_time_travel"])
      Rails.logger.info("[Time travel] Travelling to #{Current.date_after_time_travel}")
      travel_to Current.date_after_time_travel
      Rails.logger.info("[Time travel] Travelled to #{Date.current}")
    end

    yield
  ensure
    travel_back
    Current.date_before_time_travel = nil
    Current.date_after_time_travel = nil
  end
end
