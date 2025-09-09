module Schools
  module ECTs
    module ChangeNameWizard
      class CheckAnswersStep < Step
        delegate :ect_at_school_period, :author, :teacher_full_name, to: :wizard

        def previous_step
          :edit
        end

        def next_step
          :confirmation
        end

        def save!
          old_name = teacher_full_name
          ect_at_school_period.teacher.update!(corrected_name: store.name)
          new_name = teacher_full_name
          record_event(old_name, new_name)
        end

      private

        def record_event(old_name, new_name)
          ::Events::Record.teacher_name_changed_in_trs_event!(
            old_name:,
            new_name:,
            author:,
            teacher: ect_at_school_period.teacher
          )
        end
      end
    end
  end
end
