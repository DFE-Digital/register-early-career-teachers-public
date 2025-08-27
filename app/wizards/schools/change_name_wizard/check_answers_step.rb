module Schools
  module ChangeNameWizard
    class CheckAnswersStep < Step
      def previous_step
        :edit
      end

      def next_step
        :confirmation
      end

      def save!
        old_name = persisted_name
        wizard.ect.teacher.update!(corrected_name:)
        new_name = persisted_name
        record_event(old_name, new_name)
      end

    private

      def corrected_name
        Schools::Validation::CorrectedName.new(store.new_name).formatted_name
      end

      def persisted_name
        Teachers::Name.new(wizard.ect.teacher).full_name
      end

      def record_event(old_name, new_name)
        Events::Record.teacher_name_changed_in_trs_event!(
          old_name:,
          new_name:,
          author: wizard.author,
          teacher: wizard.ect.teacher
        )
      end
    end
  end
end
