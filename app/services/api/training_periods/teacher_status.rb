module API::TrainingPeriods
  class TeacherStatus
    attr_reader :started_on, :finished_on

    def initialize(latest_training_period:)
      @started_on = latest_training_period.started_on
      @finished_on = latest_training_period.finished_on
    end

    def status
      return :joining if started_on&.future?

      if finished_on.present?
        finished_on.future? ? :leaving : :left
      else
        :active # includes complete
      end
    end
  end
end
