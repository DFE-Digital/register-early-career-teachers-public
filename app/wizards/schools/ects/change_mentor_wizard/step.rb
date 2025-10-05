module Schools
  module ECTs
    module ChangeMentorWizard
      class Step < ECTs::Step
        include MentorAtSchoolPeriods::Assignable
        include LeadProviders::Assignable
      end
    end
  end
end
