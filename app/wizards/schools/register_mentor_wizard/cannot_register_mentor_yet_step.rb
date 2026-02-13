module Schools
  module RegisterMentorWizard
    class CannotRegisterMentorYetStep < Step
      def previous_step
        if store.revised_start_date_in_closed_contract_period
          store.back_to = nil
          store.revised_start_date_in_closed_contract_period = nil
          :check_answers
        else
          :started_on
        end
      end
    end
  end
end
