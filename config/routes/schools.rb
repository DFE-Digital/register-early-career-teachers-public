constraints -> { Rails.application.config.enable_schools_interface } do
  namespace :schools do
    resources :mentors, only: %i[show]

    get "/home/ects", to: "ects#index", as: :ects_home
    get "/home/mentors", to: "mentors#index", as: :mentors_home

    namespace :register_ect_wizard, path: "register-ect" do
      get "what-you-will-need", as: :start, action: :start

      concerns :wizardable, wizard: Schools::RegisterECTWizard
    end
  end
end
