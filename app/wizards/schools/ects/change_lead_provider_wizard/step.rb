module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class Step < ECTs::Step
        include LeadProviders::Assignable
      end
    end
  end
end
