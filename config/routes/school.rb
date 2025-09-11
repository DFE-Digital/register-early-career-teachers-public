namespace :schools, path: :school do
  scope module: :ects, path: "/ects/:ect_id", as: :ects do
    namespace :change_name_wizard, path: "change-name" do
      draw(:wizardable)
    end

    namespace :change_email_address_wizard, path: "change-email-address" do
      draw(:wizardable)
    end

    namespace :change_working_pattern_wizard, path: "change-working-pattern" do
      draw(:wizardable)
    end
  end

  resources :ects, only: %i[index show] do
    resource :mentorship, only: %i[new create] do
      get :confirmation, on: :collection
    end
  end

  resources :mentors, only: %i[index]

  namespace :register_mentor_wizard, path: "register-mentor" do
    get "what-you-will-need", as: :start, action: :start

    get "find-mentor", action: :new
    post "find-mentor", action: :create

    get "cannot-mentor-themself", action: :new
    post "cannot-mentor-themself", action: :create

    get "national-insurance-number", action: :new
    post "national-insurance-number", action: :create

    get "no-trn", action: :new
    get "trn-not-found", action: :new
    get "not-found", action: :new
    get "cannot-register-mentor", action: :new

    get "already-active-at-school", action: :new
    post "already-active-at-school", action: :create

    get "review-mentor-details", action: :new
    post "review-mentor-details", action: :create
    get "change-mentor-details", action: :new
    post "change-mentor-details", action: :create

    get "email-address", action: :new
    post "email-address", action: :create
    get "change-email-address", action: :new
    post "change-email-address", action: :create

    get "cant-use-changed-email", action: :new
    post "cant-use-changed-email", action: :create
    get "cant-use-email", action: :new
    post "cant-use-email", action: :create

    get "review-mentor-eligibility", action: :new
    post "review-mentor-eligibility", action: :create

    get "mentoring-at-new-school-only", action: :new
    post "mentoring-at-new-school-only", action: :create

    get "started-on", action: :new
    post "started-on", action: :create
    get "change-started-on", action: :new
    post "change-started-on", action: :create

    get "previous-training-period-details", action: :new
    post "previous-training-period-details", action: :create

    get "programme-choices", action: :new
    post "programme-choices", action: :create

    get "lead-provider", action: :new
    post "lead-provider", action: :create
    get "change-lead-provider", action: :new
    post "change-lead-provider", action: :create

    get "eligibility-lead-provider", action: :new
    post "eligibility-lead-provider", action: :create

    get "check-answers", action: :new
    post "check-answers", action: :create

    get "confirmation", action: :new
  end

  namespace :assign_existing_mentor_wizard, path: 'assign-existing-mentor' do
    get 'review-mentor-eligibility', action: :new
    post 'review-mentor-eligibility', action: :create

    get 'lead-provider', action: :new
    post 'lead-provider', action: :create

    get 'confirmation', action: :new
  end
end
