module Schedules
  class Destroy
    attr_reader :schedule, :author

    def initialize(author:, schedule:)
      @author = author
      @schedule = schedule
    end

    def destroy!
      ActiveRecord::Base.transaction do
        record_event!
        schedule.destroy!
      end
    end

  private

    def record_event!
      Events::Record.record_schedule_deleted_event!(author:, schedule:)
    end
  end
end
