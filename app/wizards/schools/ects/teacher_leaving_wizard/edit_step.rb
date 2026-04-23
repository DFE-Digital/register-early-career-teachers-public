module Schools
  module ECTs
    module TeacherLeavingWizard
      class EditStep < ECTs::Step
        attr_accessor :leaving_on

        validate :leaving_on_valid
        validate :leaving_on_after_previous_school_or_training_period_start

        def self.permitted_params
          %i[
            leaving_on
            leaving_on(1i)
            leaving_on(2i)
            leaving_on(3i)
          ]
        end

        def next_step = :check_answers

        def save!
          return false unless valid_step?

          store.leaving_on = leaving_on_input.date_as_hash
        end

      private

        def pre_populate_attributes
          return unless store.leaving_on

          self.leaving_on = Schools::Validation::LeavingDate
            .new(date_as_hash: store.leaving_on)
            .date_as_hash
        end

        def leaving_on_valid
          return if leaving_on_input.valid?

          errors.add(:leaving_on, leaving_on_input.error_message)
        end

        def skip_leaving_on_validation?
          errors[:leaving_on].any?
        end

        def leaving_on_after_previous_school_or_training_period_start
          return if skip_leaving_on_validation?
          return if leaving_on_boundary_validator.valid?

          errors.add(:leaving_on, leaving_on_boundary_validator.error_message + " Enter a later date.")
        end

        def leaving_on_input
          @leaving_on_input ||= Schools::Validation::LeavingDate.new(date_as_hash: leaving_on)
        end

        def leaving_on_boundary_validator
          @leaving_on_boundary_validator ||= Schools::Validation::PeriodBoundary.new(
            ect_at_school_period:,
            full_name: name_for(ect_at_school_period.teacher),
            date: leaving_on_input.value_as_date
          )
        end
      end
    end
  end
end
