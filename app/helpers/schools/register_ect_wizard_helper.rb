module Schools
  module RegisterECTWizardHelper
    def appropriate_body_change_path(school)
      if school&.independent?
        schools_register_ect_wizard_change_independent_school_appropriate_body_path
      else
        schools_register_ect_wizard_change_state_school_appropriate_body_path
      end
    end
  end
end
