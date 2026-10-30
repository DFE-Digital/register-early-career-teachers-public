module Admin
  module Teachers
    module ChangeTRNWizard
      class CannotUseTRNStep < Step
        def previous_step = :enter_trn
      end
    end
  end
end
