module Schedules
  class Assignment
    def initialize(ect_at_school_period:)
      @ect_at_school_period = ect_at_school_period
    end

    def self.for_ects(...) = new(...).call
 
    def call
      ActiveRecord::Base.transaction do
        if has_previous_training_periods?
          current_training_period.schedule = schedule
          current_training_period.save!
        else
          current_training_period.schedule = schedule
          current_training_period.save!
        end
      end
    end

    private

    def period
      @ect_at_school_period
    end

    def current_training_period
      period.current_or_next_training_period
    end

    def schedule
      # TODO
      Schedule.last
    end

    def contract_period
      # TODO
      ContractPeriod.all.first
    end

    def has_previous_training_periods?
      period.training_periods.where.not(id: current_training_period.id).exists?
    end

    def schedule_date
      registered_after_started_on? ? registered_on : started_on
    end

    def registered_after_start?
      registered_on > started_on
    end

    def started_on
      period.started_on
    end

    def registered_on
      # TODO
      period.started_on
    end

    def provider_led?
      # TODO
    end

    def school_led?
      # TODO
    end

    # To assign a schedule for an ECT, if the ECT does not have any previous training periods (i.e. school led or provider led) we'll use either:

    # the start date from ECT_at_school period OR,
    # the date of registration if it is after the school start date
    # This is because the ECT can't start training until they're registered, so if a school is late in registering someone, they would have to be placed on a later schedule.

    # If an ECT has a previous school-led training period but no previous provider-led periods, we'll use:

    # -the start date of the new provider-led training period

    
  end
end
