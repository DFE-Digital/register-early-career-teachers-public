module Teachers
  class MergeTRN
    module TrainingPeriods
      class Merge
        include Periods::Mergeable

        class CannotMergePeriods < StandardError; end

        def call
          raise CannotMergePeriods, "Periods have different training programmes" if periods_have_different_training_programmes?
          raise CannotMergePeriods, "Periods have different schedules" if periods_have_different_schedules?
          raise CannotMergePeriods, "Periods have different partnerships" if periods_have_different_partnerships?

          super
        end

      private

        def period_type
          :training_period
        end

        def periods_have_different_partnerships?
          periods.map(&:school_partnership_id).uniq.size > 1
        end

        def periods_have_different_training_programmes?
          periods.map(&:training_programme).uniq.size > 1
        end

        def periods_have_different_schedules?
          periods.map(&:schedule_id).uniq.size > 1
        end

        def declarations
          @declarations ||= redundant_periods.flat_map(&:declarations).uniq
        end

        def update_related_records!
          move_declarations!

          super
        end

        def move_declarations!
          declarations.each { |declaration| declaration.update!(attrs) }
        end

        def reset_related_records!(period)
          period.declarations.reset

          super
        end
      end
    end
  end
end
