module Schools
  module Mentors
    module TeacherLeavingWizard
      class EditStep < Mentors::Step
        attr_accessor :leaving_on

        validate :leaving_on_valid
        validate :leaving_after_start_date

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

        def leaving_after_start_date
          return unless leaving_on_input.valid?
          return if leaving_on_input.value_as_date >= mentor_at_school_period.started_on

          errors.add(
            :leaving_on,
            "Our records show that #{name_for(mentor_at_school_period.teacher)} started teaching at your school on
            #{mentor_at_school_period.started_on.to_formatted_s(:govuk)}. Enter a later date."
          )
        end

        def leaving_on_input
          @leaving_on_input ||= Schools::Validation::LeavingDate.new(date_as_hash: leaving_on)
        end
      end
    end
  end
end
