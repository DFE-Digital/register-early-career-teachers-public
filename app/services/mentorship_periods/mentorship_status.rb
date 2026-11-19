module MentorshipPeriods
  class MentorshipStatus
    attr_reader :mentorship_period

    def initialize(mentorship_period:)
      @mentorship_period = mentorship_period
    end

    def refresh!
      mentorship_period.transaction do
        lead_provider_ids.each do |lead_provider_id|
          status = mentorship_period
            .lead_provider_mentorship_statuses
            .strict_loading
            .includes(
              :lead_provider,
              mentorship_period: {
                mentor: [
                  :teacher,
                  {
                    training_periods: :lead_provider
                  }
                ]
              }
            )
            .find_or_create_by!(lead_provider_id:)

          status.refresh! unless status.previously_new_record?
        end
      end
    end

  private

    def lead_provider_ids
      mentorship_period
        .mentee
        .training_periods
        .joins(:lead_provider)
        .distinct
        .pluck("lead_providers.id")
    end
  end
end
