module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_appropriate_body_name = new_appropriate_body_period.display_name

      private

        def new_appropriate_body_period
          @new_appropriate_body_period ||= AppropriateBodyPeriod.find(store.appropriate_body_id)
        end
      end
    end
  end
end
