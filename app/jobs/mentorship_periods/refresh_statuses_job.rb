module MentorshipPeriods
  class RefreshStatusesJob < RecurringJob
    queue_as :default

    def perform
      MentorshipPeriod.find_each do |mentorship_period|
        MentorshipStatus.new(mentorship_period:).refresh!
      end
    end
  end
end
