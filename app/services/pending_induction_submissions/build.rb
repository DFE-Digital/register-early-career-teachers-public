module PendingInductionSubmissions
  class Build
    attr_reader :pending_induction_submission

    def initialize(...)
      @pending_induction_submission = PendingInductionSubmission.new(...)
    end

    # build a PendingInductionSubmission with the started_on date of the induction period
    # it'll be closing populated so we can compare it to the finish date when applying
    # validation
    def self.closing_induction_period(induction_period, **attributes)
      started_on = induction_period.started_on

      new(started_on:, **attributes)
    end
  end
end
