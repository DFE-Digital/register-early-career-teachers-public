module TrainingPeriods
  class Archive
    include Periods::Archive

    def self.period_class = TrainingPeriod
  end
end
