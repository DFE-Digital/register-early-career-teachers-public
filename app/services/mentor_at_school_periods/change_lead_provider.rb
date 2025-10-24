module MentorAtSchoolPeriods
  class ChangeLeadProvider

    def initialize(mentor_at_school_period, new_lead_provider)
      @mentor_at_school_period = mentor_at_school_period
      @new_lead_provider = new_lead_provider
    end

    def call
      ActiveRecord::Base.transaction do
        # TODO: do something
        # Hints
        # Close the existing training training_periods
        # Open a new training period linked to the new lead provider
        # Write some events
      end
    end

    private

    
  end
end
