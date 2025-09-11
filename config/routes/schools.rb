namespace :schools do
  resources :mentors, only: %i[show]
  get "/home/ects", to: "ects#index", as: :ects_home
  get "/home/mentors", to: "mentors#index", as: :mentors_home

  namespace :register_ect_wizard, path: "register-ect" do
    get "what-you-will-need", as: :start, action: :start

    get "find-ect", action: :new
    post "find-ect", action: :create

    get "national-insurance-number", action: :new
    post "national-insurance-number", action: :create
    get "change-national-insurance-number", action: :new
    post "change-national-insurance-number", action: :create

    get "trn-not-found", action: :new
    get "not-found", action: :new
    get "cannot-register-ect", action: :new
    get "cannot-register-ect-yet", action: :new

    get "already-active_at-school", action: :new
    get "induction-completed", action: :new
    get "induction-exempt", action: :new
    get "induction-failed", action: :new

    get "review-ect-details", action: :new
    post "review-ect-details", action: :create
    get "change-review-ect-details", action: :new
    post "change-review-ect-details", action: :create

    get "email-address", action: :new
    post "email-address", action: :create
    get "change-email-address", action: :new
    post "change-email-address", action: :create

    get "start-date", action: :new
    post "start-date", action: :create
    get "change-start-date", action: :new
    post "change-start-date", action: :create

    get "state-school-appropriate-body", action: :new
    post "state-school-appropriate-body", action: :create
    get "change-state-school-appropriate-body", action: :new
    post "change-state-school-appropriate-body", action: :create
    get "no-previous-ect-choices-change-state-school-appropriate-body", action: :new
    post "no-previous-ect-choices-change-state-school-appropriate-body", action: :create

    get "independent-school-appropriate-body", action: :new
    post "independent-school-appropriate-body", action: :create
    get "change-independent-school-appropriate-body", action: :new
    post "change-independent-school-appropriate-body", action: :create
    get "no-previous-ect-choices-change-independent-school-appropriate-body", action: :new
    post "no-previous-ect-choices-change-independent-school-appropriate-body", action: :create

    get "training-programme", action: :new
    post "training-programme", action: :create
    get "change-training-programme", action: :new
    post "change-training-programme", action: :create
    get "no-previous-ect-choices-change-training-programme", action: :new
    post "no-previous-ect-choices-change-training-programme", action: :create

    get "lead-provider", action: :new
    post "lead-provider", action: :create
    get "change-lead-provider", action: :new
    post "change-lead-provider", action: :create
    get "no-previous-ect-choices-change-lead-provider", action: :new
    post "no-previous-ect-choices-change-lead-provider", action: :create
    get "training-programme-change-lead-provider", action: :new
    post "training-programme-change-lead-provider", action: :create

    get "working-pattern", action: :new
    post "working-pattern", action: :create
    get "change-working-pattern", action: :new
    post "change-working-pattern", action: :create

    get "use-previous-ect-choices", action: :new
    post "use-previous-ect-choices", action: :create
    get "change-use-previous-ect-choices", action: :new
    post "change-use-previous-ect-choices", action: :create
    get "registered-before", action: :new
    post "registered-before", action: :create

    get "check-answers", action: :new
    post "check-answers", action: :create

    get "cant-use-email", action: :new
    post "cant-use-email", action: :create

    get "confirmation", action: :new
  end
end
