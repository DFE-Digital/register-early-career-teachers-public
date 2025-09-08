module Schools
  module ECTs
    module ChangeWorkingPatternWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def current_working_pattern = ect_at_school_period.working_pattern
        def new_working_pattern = store.working_pattern

        def save!
          ApplicationRecord.transaction do
            old_working_pattern = current_working_pattern
            ect_at_school_period.update!(working_pattern: new_working_pattern)
            Events::Record.record_teacher_working_pattern_updated_event!(
              old_working_pattern:,
              new_working_pattern:,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )
            true
          end
        end
      end
    end
  end
end
