FactoryBot.define do
  factory(:register_ect_wizard, class: "Schools::RegisterECTWizard::Wizard") do
    skip_create
    initialize_with { new(current_step:, step_params:, store:, school:) }

    current_step { :find_mentor }
    step_params { {} }
    store { FactoryBot.create(:session_repository) }
    school { FactoryBot.create(:school, gias_school: FactoryBot.create(:gias_school, :state_school_type)) }
  end
end
