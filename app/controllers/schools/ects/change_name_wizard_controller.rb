module Schools
  module ECTs
    class ChangeNameWizardController < ECTs::ChangeECTWizardController
      # @return [Schools::ECTs::ChangeNameWizard::Wizard]
      def initialize_wizard
        @wizard = ChangeNameWizard::Wizard.new(
          store:,
          current_step:,
          ect_at_school_period:,
          author: current_user,
          step_params: params
        )
      end

      # @return [SessionRepository]
      def store
        @store ||= SessionRepository.new(session:, form_key: :change_name_wizard)
      end
    end
  end
end
