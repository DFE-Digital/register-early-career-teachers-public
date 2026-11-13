module ECTAtSchoolPeriods
  class Archive
    include Periods::Archive

    def self.period_class = ECTAtSchoolPeriod
  end
end
