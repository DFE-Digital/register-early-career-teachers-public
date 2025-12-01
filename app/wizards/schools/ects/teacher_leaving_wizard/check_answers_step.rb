module Schools
  module ECTs
    module TeacherLeavingWizard
      class CheckAnswersStep < ECTs::Step
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
          return false unless leaving_date

          report_teacher_leaving!(leaving_date)
          true
        end

      private

        def pre_populate_attributes
          self.leaving_on = store.leaving_on
        end

        def report_teacher_leaving!(finished_on)
          ECTAtSchoolPeriods::Finish.new(
            ect_at_school_period:,
            finished_on:,
            author:
          ).finish!
        end
      end
    end
  end
end
