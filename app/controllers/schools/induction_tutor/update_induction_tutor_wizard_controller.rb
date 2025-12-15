module Schools
  module InductionTutor
    class UpdateInductionTutorWizardController < SchoolsController
      include InductionTutorable
    end
  end
end
