module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class Step < ECTs::Step
        include LeadProviders::Assignable
      end
    end
  end
end
