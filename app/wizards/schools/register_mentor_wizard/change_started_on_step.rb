module Schools
  module RegisterMentorWizard
    class ChangeStartedOnStep < StartedOnStep
      def next_step
        if !contract_period.enabled?
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
      def contract_period
        @contract_period ||= ContractPeriod
          .containing_date(started_on_as_date)
      end

      def persist
        if contract_period.enabled?
          super
        else
          wizard.store.started_on = mentor.started_on&.to_date

          true
        end
      end
    end
  end
end
