module PendingInductionSubmissions
  class Search
    attr_reader :scope

    def initialize(appropriate_body_period: nil)
      @scope = PendingInductionSubmission.all

      where_appropriate_body_period_is(appropriate_body_period)
    end

    def pending_induction_submissions
      @scope
    end

  private

    def where_appropriate_body_period_is(appropriate_body_period)
      return unless appropriate_body_period

      scope.merge!(PendingInductionSubmission.where(appropriate_body_period:))
    end
  end
end
