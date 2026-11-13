module MentorshipPeriods
  class Archive
    include Periods::Archive

    def self.period_class = MentorshipPeriod
  end
end
