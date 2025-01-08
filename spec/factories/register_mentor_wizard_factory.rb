FactoryBot.define do
  factory(:register_mentor_wizard, class: "Schools::RegisterMentorWizard::Wizard") do
    skip_create
    initialize_with { new(current_step:, step_params:, ect_id:, store:) }

    current_step { :find_mentor }
    ect_id { Faker::Number.within(range: 5400..6000) }
    step_params { {} }
    store { FactoryBot.create(:session_repository) }
  end
end
