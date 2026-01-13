module Schools
  module RegisterECTWizard
    class ChangeStartDateStep < StartDateStep
      def next_step
        :check_answers
      end

      def previous_step
        :check_answers
      end

    private

      def persist
        super

        ect.update!(use_previous_ect_choices: nil)
        store[:school_partnership_to_reuse_id] = nil

        true
      end
    end
  end
end
