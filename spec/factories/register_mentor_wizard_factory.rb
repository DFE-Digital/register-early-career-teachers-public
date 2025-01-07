FactoryBot.define do
  factory(:register_mentor_wizard, class: "Schools::RegisterMentorWizard::Wizard") do
    initialize_with do
      new(current_step:,
          step_params: {},
          ect_id: Faker::Number.within(range: 5400..6000),
          store: FactoryBot.create(:session_repository))
    end
  end
end
