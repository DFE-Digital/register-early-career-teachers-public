module MentorshipPeriods
  class RefreshStatusesJob < RecurringJob
    queue_as :default

    def perform
      LeadProviderMentorshipStatus
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
        .find_each(&:refresh!)
    end
  end
end
