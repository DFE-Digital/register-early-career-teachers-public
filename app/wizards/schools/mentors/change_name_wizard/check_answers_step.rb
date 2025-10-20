module Schools
  module Mentors
    module ChangeNameWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def save!
          ApplicationRecord.transaction do
            old_name = wizard.teacher_full_name
            mentor_at_school_period.teacher.update!(corrected_name: store.name)
            new_name = wizard.teacher_full_name
            record_event(old_name, new_name)
          end
        end

        private

        def record_event(old_name, new_name)
          ::Events::Record.teacher_name_changed_in_trs_event!(
            old_name:,
            new_name:,
            author:,
            teacher: mentor_at_school_period.teacher
          )
        end
      end
    end
  end
end
