module API::TrainingPeriods
  class TeacherStatus
    attr_reader :started_on, :finished_on

    def initialize(latest_training_period:)
      @started_on = latest_training_period.started_on
      @finished_on = latest_training_period.finished_on
    end

    def status
      if finished_on.present?
        finished_on.future? ? :leaving : :left
      elsif started_on&.future?
        :joining
      else
        :active # includes complete
      end
    end
  end
end
