module Schedules
  class Assignment
    attr_accessor :training_period

    def initialize(training_period:)
      @training_period = training_period
    end

    def self.for_ects(...) = new(...).call
 
    def call
      # if the trainging period is school-led DO NOTHING
      return unless provider_led?

      # (1) is this the first training period for an ECT?

      # if has_previous_training_periods?
      #   # YES
      #   # Then the previous training period must either be school-led or provider-led
      #   # If it is school led
      #   # Then set the schedule based on the start date of this new provider-led training period
      #   # If it is provider led
      #   # Then the ECT is already on a schedule AND WHAT SHOULD WE DO???
      # else
        # NO
        # Then set the schedule based on a date
        training_period.schedule = schedule
        training_period.save!
      # end

      
      


    end

    private

    def provider_led?
      training_period.training_programme == "provider_led"
    end


    def period
      training_period.ect_at_school_period
    end
    

 
    def schedule
      Schedule.where(contract_period_year:, identifier: ).first
    end

    def contract_period_year
      training_period.contract_period.year
    end

    # TODO - this assumes the training period has been committed to the DB
    def has_previous_training_periods?
      period.training_periods.where.not(id: training_period.id).exists?
    end

    def schedule_date
      return started_on if has_previous_training_periods?

      [started_on, registered_on].max
    end

    def started_on
      training_period.started_on
    end

    def registered_on
      period.created_at.to_date
    end

    def schedule_month
      if (june_start..october_end).cover?(schedule_date)
        'september'
      elsif (november_start..february_end).cover?(schedule_date)
        'january'
      elsif (march_start..may_end).cover?(schedule_date)
        'april'
      end
    end

    def next_year
      contract_period_year + 1
    end

    def june_start
      Date.new(contract_period_year, 6, 1)
    end

    def october_end
      november_start - 1
    end

    def november_start
      Date.new(contract_period_year, 11, 1)
    end

    def february_end
      march_start - 1
    end

    def march_start
      Date.new(next_year, 3, 1)
    end

    def may_end
      Date.new(next_year, 5, 31)
    end

    def schedule_type
      # TODO
      'standard' # or 'extended' or 'reduced' or 'replacement'
    end

    def identifier
      "ecf-#{schedule_type}-#{schedule_month}"
    end


    # To assign a schedule for an ECT, if the ECT does not have any previous training periods (i.e. school led or provider led) we'll use either:

    # the start date from ECT_at_school period OR,
    # the date of registration if it is after the school start date
    # This is because the ECT can't start training until they're registered, so if a school is late in registering someone, they would have to be placed on a later schedule.

    # If an ECT has a previous school-led training period but no previous provider-led periods, we'll use:

    # -the start date of the new provider-led training period

    
  end
end
