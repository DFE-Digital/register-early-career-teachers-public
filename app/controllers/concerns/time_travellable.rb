require "active_support/testing/time_helpers"

module TimeTravellable
  extend ActiveSupport::Concern
  include ActiveSupport::Testing::TimeHelpers

  included do
    before_action :set_time_travelled_date,
                  if: -> { Rails.application.config.enable_time_travel }
    before_action :travel_in_time,
                  if: -> { Rails.application.config.enable_time_travel }
  end

private

  def set_time_travelled_date
    Current.time_travelled_date = session["time_travelled_date"]
  end

  def travel_in_time
    travel_to Current.time_travelled_date if Current.time_travelled_date
  end
end
