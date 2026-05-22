module Schedules
  class Create
    attr_reader :author,
                :schedule

    def initialize(author:, contract_period_year:, identifier:)
      @author = author
      @schedule = Schedule.new(contract_period_year:, identifier:)
    end

    def create!
      return false unless schedule.valid?

      ActiveRecord::Base.transaction do
        schedule.save!
        record_event!
      end

      schedule
    end

  private

    def record_event!
      Events::Record.record_schedule_added_event!(author:, schedule:)
    end
  end
end
