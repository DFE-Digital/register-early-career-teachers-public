module Schools
  module InductionTutor
    class UpdateInductionTutorWizardController < SchoolsController
      include InductionTutorable

    private

      def start_journey
        state_store.clear unless request.referer.to_s.include?("/school/induction-tutor/update-induction-tutor/")

        super
      end
    end
  end
end
