module Schools
  module Mentors
    module TeacherLeavingWizard
      class CheckAnswersStep < Mentors::Step
        attr_accessor :leaving_on

        def previous_step = :edit

        def next_step = :confirmation

        def leaving_date
          return if leaving_on.blank?

          Schools::Validation::LeavingDate
            .new(date_as_hash: leaving_on)
            .value_as_date
        end

        def save!
          date = leaving_date
          return false unless date

          report_teacher_leaving!(date)
          true
        end

      private

        def pre_populate_attributes
          self.leaving_on = store.leaving_on
        end

        def report_teacher_leaving!(finished_on)
          MentorAtSchoolPeriods::Finish.new(
            teacher: mentor_at_school_period.teacher,
            finished_on:,
            author:
          ).finish_existing_at_school_periods!
        end
      end
    end
  end
end
