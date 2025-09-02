module Schools
  module ChangeECTNameWizard
    class CheckAnswersStep < Step
      def previous_step
        :edit
      end

      def next_step
        :confirmation
      end

      def save!
        old_name = persisted_name
        wizard.ect_at_school_period.teacher.update!(corrected_name:)
        new_name = persisted_name
        record_event(old_name, new_name)
      end

    private

      def corrected_name
        Schools::Validation::CorrectedName.new(store.new_name).formatted_name
      end

      def persisted_name
        Teachers::Name.new(wizard.ect_at_school_period.teacher.reload).full_name
      end

      def record_event(old_name, new_name)
        Events::Record.teacher_name_changed_in_trs_event!(
          old_name:,
          new_name:,
          author: wizard.author,
          teacher: wizard.ect_at_school_period.teacher
        )
      end
    end
  end
end
