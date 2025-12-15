module Schools
  module InductionTutor
    class ConfirmExistingInductionTutorWizardController < SchoolsController
      include InductionTutorable
    end
  end
end
