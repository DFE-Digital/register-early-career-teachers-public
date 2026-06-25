module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        delegate :name, to: :new_appropriate_body_period, prefix: :new_appropriate_body

      private

        def new_appropriate_body_period
          @new_appropriate_body_period ||= AppropriateBodyPeriod.find(store.appropriate_body_id)
        end
      end
    end
  end
end
