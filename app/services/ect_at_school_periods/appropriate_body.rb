module ECTAtSchoolPeriods
  class AppropriateBody
    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    delegate :name, to: :appropriate_body

    def from_induction? = claimed_by_appropriate_body.present?

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

    # The ongoing induction period that represents an AB claiming the ECT for
    # *this* school placement (i.e. started within this placement's dates).
    # Claims recorded before the school registered the ECT, or carried over from
    # a previous school, are excluded, so the school keeps seeing its reported
    # appropriate body as provisional until it's confirmed for this placement.
    def claimed_by_appropriate_body
      if ongoing_induction_period&.started_on.in?(@ect_at_school_period.range)
        ongoing_induction_period.appropriate_body_period
      else
        NullAppropriateBody.new
      end
    end

    def ongoing_induction_period
      @ect_at_school_period.teacher.ongoing_induction_period
    end

    NullAppropriateBody = Data.define do
      def present? = false
      def name = "Not reported"
    end
  end
end
