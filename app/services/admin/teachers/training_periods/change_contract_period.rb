module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriod
        class UnsupportedTrainingPeriodError < StandardError; end
        class ScheduleNotFoundError < StandardError; end
        class FrameworkAgreementNotFoundError < StandardError; end
      end
    end
  end
end
