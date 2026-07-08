module API::MentorshipPeriods
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider_id:)
      @scope = MentorshipPeriod.current_or_future

      where_lead_provider(lead_provider_id)
    end

    def mentorship_periods
      preload_associations(block_given? ? yield(scope) : scope)
    end

  private

    def preload_associations(results)
      results
        .strict_loading
        .includes(
          mentee: %i[teacher school],
          mentor: [
            :teacher,
            { training_periods: :lead_provider }
          ]
        )
    end

    def where_lead_provider(lead_provider_id)
      @scope = scope
        .joins(mentee: { training_periods: :lead_provider })
        .where(
          lead_providers: {
            id: lead_provider_id,
          }
        )
    end
  end
end
