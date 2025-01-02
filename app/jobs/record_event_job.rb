class RecordEventJob < ApplicationJob
  queue_as :events

  def perform(...)
    Event.create!(...)
  end
end
