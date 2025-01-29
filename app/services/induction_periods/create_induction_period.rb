module InductionPeriods
  class CreateInductionPeriod
    attr_reader :induction_period,
                :event,
                :started_on,
                :teacher,
                :appropriate_body,
                :induction_programme,
                :author

    def initialize(teacher:, appropriate_body:, started_on:, induction_programme:)
      @teacher = teacher
      @appropriate_body = appropriate_body
      @started_on = started_on
      @induction_programme = induction_programme
    end

    def create_induction_period(author:)
      @induction_period = InductionPeriod.create(teacher:, appropriate_body:, started_on:, induction_programme:)

      if @induction_period.persisted?
        Events::Record.record_appropriate_body_claims_teacher_event!(
          author:,
          teacher:,
          appropriate_body:,
          induction_period:
        )
      end

      @induction_period
    end
  end
end
