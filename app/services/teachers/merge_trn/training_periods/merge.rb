module Teachers
  class MergeTRN
    module TrainingPeriods
      class Merge
        include Periods::Mergeable

        class CannotMergePeriods < StandardError; end

        def call
          training_periods_are_incompatible?

          super
        end

      private

        def period_type
          :training_period
        end

        def incompatible_attributes
          %i[deferral_reason
             expression_of_interest_id
             schedule_id
             school_partnership_id
             withdrawal_reason]
        end

        def training_periods_are_incompatible?
          incompatible_attributes.each do |attribute|
            attribute_name = attribute.to_s.humanize.pluralize.downcase

            if periods_have_different?(attribute)
              raise CannotMergePeriods, "Periods have different #{attribute_name}"
            end
          end
        end

        def periods_have_different?(attribute)
          periods.map(&attribute).uniq.size > 1
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
