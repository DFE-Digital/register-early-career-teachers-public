constraints -> { Rails.application.config.enable_schools_interface } do
  namespace :schools, path: :school do
    get "/home/ects", to: "ects#index", as: :ects_home
    resources :ects, only: %i[index show] do
      resource :mentorship, only: %i[new create] do
        get :confirmation
      end
    end

    get "/home/mentors", to: "mentors#index", as: :mentors_home
    resources :mentors, only: %i[index show]

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

      namespace :change_mentor_wizard, path: "change-mentor" do
        concerns :wizardable, wizard: Schools::ECTs::ChangeMentorWizard
      end

      namespace :change_lead_provider_wizard, path: "change-lead-provider" do
        concerns :wizardable, wizard: Schools::ECTs::ChangeLeadProviderWizard
      end

      namespace :teacher_leaving_wizard, path: "report-teacher-leaving" do
        concerns :wizardable, wizard: Schools::ECTs::TeacherLeavingWizard
      end
    end

    scope module: :mentors, path: "/mentors/:mentor_id", as: :mentors do
      namespace :change_name_wizard, path: "change-name" do
        concerns :wizardable, wizard: Schools::Mentors::ChangeNameWizard
      end

      namespace :change_email_address_wizard, path: "change-email-address" do
        concerns :wizardable, wizard: Schools::Mentors::ChangeEmailAddressWizard
      end

      namespace :change_lead_provider_wizard, path: "change-lead-provider" do
        concerns :wizardable, wizard: Schools::Mentors::ChangeLeadProviderWizard
      end

      namespace :teacher_leaving_wizard, path: "report-teacher-leaving" do
        concerns :wizardable, wizard: Schools::Mentors::TeacherLeavingWizard
      end
    end

    namespace :register_ect_wizard, path: "register-ect" do
      get "what-you-will-need", as: :start, action: :start

      concerns :wizardable, wizard: Schools::RegisterECTWizard
    end

    namespace :register_mentor_wizard, path: "register-mentor" do
      get "what-you-will-need", as: :start, action: :start

      concerns :wizardable, wizard: Schools::RegisterMentorWizard
    end

    namespace :assign_existing_mentor_wizard, path: "assign-existing-mentor" do
      concerns :wizardable, wizard: Schools::AssignExistingMentorWizard
    end

    get "/home/induction-tutor", to: "induction_tutor#show", as: :induction_tutor

    namespace :induction_tutor, path: "induction-tutor" do
      namespace :confirm_existing_induction_tutor_wizard, path: "confirm-existing-induction-tutor" do
        concerns :wizardable, wizard: Schools::InductionTutor::ConfirmExistingInductionTutorWizard
      end

      namespace :new_induction_tutor_wizard, path: "new-induction-tutor" do
        concerns :wizardable, wizard: Schools::InductionTutor::NewInductionTutorWizard
      end

      namespace :update_induction_tutor_wizard, path: "update-induction-tutor" do
        concerns :wizardable, wizard: Schools::InductionTutor::UpdateInductionTutorWizard
      end
    end

    resources :support_queries, only: %i[new create]
  end
end
