module MentorAtSchoolPeriods
  class Archive
    include Periods::Archive

    def self.period_class = MentorAtSchoolPeriod
  end
end
