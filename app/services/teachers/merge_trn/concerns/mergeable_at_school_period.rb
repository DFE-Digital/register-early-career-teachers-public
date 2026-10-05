module Teachers
  class MergeTRN
    module Concerns
      module MergeableAtSchoolPeriod
        include Teachers::MergeTRN::Concerns::MergeablePeriod

      private

        def redundant_periods
          @redundant_periods ||= periods.excluding(successor_period)
        end

        def training_periods
          @training_periods ||= redundant_periods.flat_map(&:training_periods).uniq
        end

        def mentorship_periods
          @mentorship_periods ||= redundant_periods.flat_map(&:mentorship_periods).uniq
        end

        def mentorship_attrs
          attribute_name = period_type == :ect_at_school_period ? :mentee : :mentor

          { attribute_name => successor_period }
        end

        def update_related_records!
          update_mentorship_periods!
          update_training_periods!

          super
        end

        def update_mentorship_periods!
          mentorship_periods.each { |period| period.update!(mentorship_attrs) }
        end

        def update_training_periods!
          overlapping_training_periods.each do |periods|
            Teachers::MergeTRN::TrainingPeriods::Merge.call(periods:, destination:)
          end

          merged_training_periods = overlapping_training_periods.flat_map(&:itself).uniq

          training_periods.each do |period|
            next if merged_training_periods.include?(period)

            period.update!(attrs)
          end
        end

        def overlapping_training_periods
          @overlapping_training_periods ||= Teachers::MergeTRN::Overlapping.find(periods: source_and_destination_training_periods)
        end

        def source_and_destination_training_periods
          training_periods + successor_period.training_periods
        end

        def reset_related_records!(period)
          period.training_periods.reset
          period.mentorship_periods.reset

          super
        end
      end
    end
  end
end
