module API::Teachers::MentorshipPeriods
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider_id:)
      @scope = Teacher.distinct

      with_mentorship_periods
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
          lead_provider_metadata: {
            latest_ect_training_period: {
              ect_at_school_period: {
                school: {},
                mentorship_periods: {
                  mentor: :teacher
                }
              },
            }
          }
        )
    end

    def where_lead_provider(lead_provider_id)
      @scope = scope
        .joins(:lead_provider_metadata)
        .where(
          lead_provider_metadata: {
            lead_provider_id:,
          }
        )
    end

    def with_mentorship_periods
      @scope = scope.joins(
        lead_provider_metadata: {
          latest_ect_training_period: {
            ect_at_school_period: :mentorship_periods,
          }
        }
      )
    end
  end
end
