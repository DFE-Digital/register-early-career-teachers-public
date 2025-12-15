module Schools
  module InductionTutor
    class NewInductionTutorWizardController < SchoolsController
      include InductionTutorable
    end
  end
end
