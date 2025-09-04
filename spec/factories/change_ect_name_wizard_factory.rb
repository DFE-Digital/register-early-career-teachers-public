FactoryBot.define do
  factory(:change_ect_name_wizard, class: "Schools::ECTs::ChangeNameWizard::Wizard") do
    skip_create
    initialize_with { new(current_step:, step_params:, store:) }

    current_step { :edit }
    step_params { {} }
    store { FactoryBot.build(:session_repository) }
  end
end
