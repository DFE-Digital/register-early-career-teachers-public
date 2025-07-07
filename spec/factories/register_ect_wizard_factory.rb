FactoryBot.define do
  factory(:register_ect_wizard, class: "Schools::RegisterECTWizard::Wizard") do
    skip_create
    initialize_with { new(current_step:, step_params:, store:, school:) }

    current_step { :find_ect }
    step_params { {} }
    store { build(:session_repository) }
    school { create(:school, :state_funded) }
  end
end
