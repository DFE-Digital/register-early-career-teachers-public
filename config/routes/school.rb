constraints -> { Rails.application.config.enable_schools_interface } do
  namespace :schools, path: :school do
    get "/home/ects", to: "ects#index", as: :ects_home
    get "/home/mentors", to: "mentors#index", as: :mentors_home

    scope module: :ects, path: "/ects/:ect_id", as: :ects do
      namespace :change_name_wizard, path: "change-name" do
        concerns :wizardable, wizard: Schools::ECTs::ChangeNameWizard
      end

      namespace :change_email_address_wizard, path: "change-email-address" do
        concerns :wizardable, wizard: Schools::ECTs::ChangeEmailAddressWizard
      end

      namespace :change_working_pattern_wizard, path: "change-working-pattern" do
        concerns :wizardable, wizard: Schools::ECTs::ChangeWorkingPatternWizard
      end

      namespace :change_training_programme_wizard, path: "change-training-programme" do
        concerns :wizardable, wizard: Schools::ECTs::ChangeTrainingProgrammeWizard
      end
    end

    resources :ects, only: %i[index show] do
      resource :mentorship, only: %i[new create] do
        get :confirmation, on: :collection
      end
    end

    scope module: :mentors, path: "/mentors/:mentor_id", as: :mentors do
      namespace :change_name_wizard, path: "change-name" do
        concerns :wizardable, wizard: Schools::Mentors::ChangeNameWizard
      end

      namespace :change_email_address_wizard, path: "change-email-address" do
        concerns :wizardable, wizard: Schools::Mentors::ChangeEmailAddressWizard
      end
    end

    resources :mentors, only: %i[index show]

    namespace :register_ect_wizard, path: "register-ect" do
      get "what-you-will-need", as: :start, action: :start

      concerns :wizardable, wizard: Schools::RegisterECTWizard
    end

    namespace :register_mentor_wizard, path: "register-mentor" do
      get "what-you-will-need", as: :start, action: :start

      concerns :wizardable, wizard: Schools::RegisterMentorWizard
    end

    namespace :assign_existing_mentor_wizard, path: 'assign-existing-mentor' do
      concerns :wizardable, wizard: Schools::AssignExistingMentorWizard
    end
  end
end
