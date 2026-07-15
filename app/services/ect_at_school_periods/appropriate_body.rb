module ECTAtSchoolPeriods
  class AppropriateBody
    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    delegate :name, to: :appropriate_body

    def from_induction? = induction_periods_reported_during_placement.any?

    def from_school?
      return false if from_induction?

      @ect_at_school_period.school_reported_appropriate_body.present?
    end

  private

    def appropriate_body
      claimed_by_appropriate_body.presence ||
        @ect_at_school_period.school_reported_appropriate_body.presence ||
        NullAppropriateBody.new
    end

    def claimed_by_appropriate_body
      induction_periods_reported_during_placement.first&.appropriate_body_period
    end

    # The ongoing induction period that represents an AB claiming the ECT for
    # *this* school placement (i.e. started within this placement's dates).
    # Claims recorded before the school registered the ECT, or carried over from
    # a previous school, are excluded, so the school keeps seeing its reported
    # appropriate body as provisional until it's confirmed for this placement.
    def induction_periods_reported_during_placement
      @ect_at_school_period
        .teacher
        .induction_periods
        .ongoing
        .where(started_on: @ect_at_school_period.started_on..@ect_at_school_period.finished_on)
        .latest_first
    end

    NullAppropriateBody = Data.define do
      def name = "Not reported"
    end
  end
end
