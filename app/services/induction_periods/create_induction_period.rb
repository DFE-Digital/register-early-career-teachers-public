module InductionPeriods
  class CreateInductionPeriod
    attr_reader :induction_period,
                :event,
                :started_on,
                :teacher,
                :appropriate_body,
                :induction_programme,
                :author,
                :finished_on,
                :number_of_terms

    # @param teacher [Teacher]
    # @param appropriate_body [AppropriateBody]
    # @param started_on [Date]
    # @param induction_programme [String]
    # @param finished_on [Date, nil]
    # @param number_of_terms [Integer, nil]
    def initialize(teacher:, appropriate_body:, started_on:, induction_programme:, finished_on: nil, number_of_terms: nil)
      @teacher = teacher
      @appropriate_body = appropriate_body
      @started_on = started_on
      @induction_programme = induction_programme
      @finished_on = finished_on
      @number_of_terms = number_of_terms
    end

    # @param author [Sessions::User]
    # @return [InductionPeriod]
    # @raise [ActiveRecord::RecordInvalid, ActiveRecord::Rollback]
    def create_induction_period!(author:)
      modifications = InductionPeriod.new(
        teacher:,
        appropriate_body:,
        started_on:,
        induction_programme:,
        finished_on:,
        number_of_terms:
      ).changes

      ActiveRecord::Base.transaction do
        @induction_period = InductionPeriod.create!(
          teacher:,
          appropriate_body:,
          started_on:,
          induction_programme:,
          finished_on:,
          number_of_terms:
        )

        success = record_event(author, modifications)

        success or raise ActiveRecord::Rollback
      end

      @induction_period
    end

  private

    # @param author [Sessions::User]
    # @param modifications [Hash{String => Array}]
    def record_event(author, modifications)
      return unless @induction_period.persisted?

      Events::Record.record_induction_period_opened_event!(
        author:,
        teacher:,
        appropriate_body:,
        induction_period:,
        modifications:
      )
    end
  end
end
