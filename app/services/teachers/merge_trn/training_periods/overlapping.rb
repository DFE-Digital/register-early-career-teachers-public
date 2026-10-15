module Teachers
  class MergeTRN
    module TrainingPeriods
      class Overlapping
        include Teachers::MergeTRN::Concerns::Overlapping

      private

        def period_type
          :training_period
        end
      end
    end
  end
end
