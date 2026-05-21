module Schools
  module InductionTutor
    class UpdateInductionTutorWizardController < SchoolsController
      include InductionTutorable

      before_action :reset_wizard

    private

      def reset_wizard
        return if request.referer.to_s.include?("/school/induction-tutor/update-induction-tutor/")

        store.reset if current_step == :edit
      end
    end
  end
end
