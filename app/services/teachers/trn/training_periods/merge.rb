module Teachers
  module TRN
    module TrainingPeriods
      class Merge
        include Periods::Mergeable

        class CannotMergePeriods < StandardError; end

        def call
          training_periods_are_incompatible?
          capture_original_period_associations!

          super
        end

      private

        def capture_original_period_associations!
          @original_period_associations = periods.to_h do |period|
            [
              period.id,
              period.slice(:expression_of_interest_id, :school_partnership_id)
            ]
          end
        end

        def period_type
          :training_period
        end

        def incompatible_attributes
          %i[training_programme
             deferral_reason
             expression_of_interest_id
             schedule_id
             school_partnership_id
             withdrawal_reason]
        end

        def training_periods_are_incompatible?
          incompatible_attributes.each do |attribute|
            next if %i[expression_of_interest_id school_partnership_id].include?(attribute) &&
              compatible_school_partnership_and_expressions_of_interest?

            attribute_name = attribute.to_s.humanize.pluralize.downcase

            if periods_have_different?(attribute)
              raise CannotMergePeriods, "Periods have different #{attribute_name}"
            end
          end
        end

        def compatible_school_partnership_and_expressions_of_interest?
          school_partnerships = periods.map(&:school_partnership).compact.uniq
          return false unless school_partnerships.size == 1

          school_partnership = school_partnerships.first

          periods.all? do |period|
            period.school_partnership == school_partnership ||
              period.expression_of_interest == school_partnership.framework_agreement
          end
        end

        def periods_have_different?(attribute)
          periods.map(&attribute).uniq.size > 1
        end

        def record_event!
          Events::Record.record_teacher_training_periods_merged!(
            teacher:,
            successor_period:,
            periods:,
            author:,
            original_period_associations: @original_period_associations
          )

          record_school_partnership_assigned!
        end

        def record_school_partnership_assigned!
          original_associations = @original_period_associations.fetch(successor_period.id)
          school_partnership = successor_period.school_partnership

          return if school_partnership.blank?
          return if original_associations.fetch(:school_partnership_id) == school_partnership.id

          Events::Record.record_training_period_assigned_to_school_partnership_event!(
            author:,
            training_period: successor_period,
            ect_at_school_period: successor_period.ect_at_school_period,
            mentor_at_school_period: successor_period.mentor_at_school_period,
            teacher: successor_period.teacher,
            school_partnership:,
            lead_provider: school_partnership.lead_provider,
            delivery_partner: school_partnership.delivery_partner,
            school: school_partnership.school
          )
        end

        def declarations
          @declarations ||= redundant_periods.flat_map(&:declarations).uniq
        end

        def update_related_records!
          successor_period.school_partnership ||= periods.filter_map(&:school_partnership).first
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
