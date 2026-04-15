module Schools
  module RegisterMentorWizard
    class ChangeStartedOnStep < StartedOnStep
      def next_step
        if registrations_closed_for_contract_period?
          wizard.store.revised_start_date_in_closed_contract_period = true
          :cannot_register_mentor_yet
        else
          :check_answers
        end
      end

      def previous_step
        :check_answers
      end

    private

      def persist
        if registrations_closed_for_contract_period?
          wizard.store.started_on = mentor.started_on&.to_date
          true
        else
          super
        end
      end
    end
  end
end
