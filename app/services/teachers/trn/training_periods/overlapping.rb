module Teachers
  module TRN
    module TrainingPeriods
      class Overlapping
        include Teachers::TRN::Concerns::Overlapping

      private

        def period_type
          :training_period
        end
      end
    end
  end
end
