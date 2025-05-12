Rails.application.routes.draw do
  root to: 'pages#home'
  get '/support', to: 'pages#support'
  get '/cookies', to: 'pages#cookies'
  get '/accessibility', to: 'pages#accessibility'
  get '/privacy', to: 'pages#privacy'

  get "healthcheck" => "health_check#show", as: :rails_health_check

  scope via: :all do
    get '/404', to: 'errors#not_found'
    get '/422', to: 'errors#unprocessable_entity'
    get '/429', to: 'errors#too_many_requests'
    get '/500', to: 'errors#internal_server_error'
  end

  # omniauth sign-in
  get '/auth/:provider/callback', to: 'sessions#create'
  post '/auth/:provider/callback', to: 'sessions#create'
  get '/sign-in', to: 'sessions#new'
  get '/sign-out', to: 'sessions#destroy'

  # one time password
  get '/otp-sign-in', to: 'otp_sessions#new'
  post '/otp-sign-in', to: 'otp_sessions#create'
  get '/otp-sign-in/code', to: 'otp_sessions#request_code'
  post '/otp-sign-in/verify', to: 'otp_sessions#verify_code'

  constraints -> { Rails.application.config.enable_personas } do
    resources 'personas', only: %i[index]
  end

  get '/admin', to: redirect('admin/teachers')

  namespace :admin do
    constraints -> { Rails.application.config.enable_blazer } do
      mount Blazer::Engine, at: "blazer"
    end

    resources :users, only: %i[index]

    resources :organisations, only: %i[index] do
      collection do
        resources :appropriate_bodies, only: %i[index show], path: 'appropriate-bodies' do
          resources :current_ects, only: :index, path: 'current-ects', controller: 'appropriate_bodies/current_ects'
        end
        resources :schools, only: %i[index show], param: :urn
      end
    end

    resources :teachers, only: %i[index show] do
      resource :timeline, only: %i[show], controller: 'teachers/timeline'
      resources :induction_periods, only: %i[new create edit update], path: 'induction-periods'
      resource :record_passed_outcome, only: %i[new create show], path: 'record-passed-outcome', controller: 'teachers/record_passed_outcome'
      resource :record_failed_outcome, only: %i[new create show], path: 'record-failed-outcome', controller: 'teachers/record_failed_outcome'
      resource :reopen_induction, only: %i[update], path: 'reopen-induction', controller: 'teachers/reopen_induction'
    end
  end

  resource :appropriate_bodies, only: %i[show], path: 'appropriate-body', as: 'ab_landing', controller: 'appropriate_bodies/landing'
  namespace :appropriate_bodies, path: 'appropriate-body', as: 'ab' do
    resources :teachers, only: %i[show index], controller: 'teachers' do
      resource :release_ect, only: %i[new create show], path: 'release', controller: 'teachers/release_ect'
      resource :record_passed_outcome, only: %i[new create show], path: 'record-passed-outcome', controller: 'teachers/record_passed_outcome'
      resource :record_failed_outcome, only: %i[new create show], path: 'record-failed-outcome', controller: 'teachers/record_failed_outcome'

      resources :extensions, controller: 'teachers/extensions', only: %i[show edit update index new create]
      resources :initial_teacher_training_records, path: 'itt-data', controller: 'teachers/initial_teacher_training_records', only: :index
    end

    namespace :claim_an_ect, path: 'claim-an-ect' do
      resource :find_ect, only: %i[new create], path: 'find-ect', controller: '/appropriate_bodies/claim_an_ect/find_ect', as: 'find'
      resources :check_ect, only: %i[edit update], path: 'check-ect', controller: '/appropriate_bodies/claim_an_ect/check_ect', as: 'check'
      resources :register_ect, only: %i[edit update show], path: 'register-ect', controller: '/appropriate_bodies/claim_an_ect/register_ect', as: 'register'

      namespace :errors do
        get 'induction-already-completed/:id', to: '/appropriate_bodies/claim_an_ect/errors#induction_already_completed', as: 'already_complete'
        get 'induction-with-another-appropriate-body/:id', to: '/appropriate_bodies/claim_an_ect/errors#induction_with_another_appropriate_body', as: 'another_ab'
        get 'no-qts/:id', to: '/appropriate_bodies/claim_an_ect/errors#no_qts', as: 'no_qts'
        get 'prohibited-from-teaching/:id', to: '/appropriate_bodies/claim_an_ect/errors#prohibited_from_teaching', as: 'prohibited'
      end
    end
  end

  namespace :migration do
    resources :migrations, only: %i[index create], path: "/" do
      collection do
        get "download_report/:model", action: :download_report, as: :download_report
        post "reset", action: :reset, as: :reset
      end
    end
    resources :failures, only: %i[index]
    resources :teacher_failures, path: "teacher-failures", only: %i[index]
    resources :teachers, only: %i[index show]
  end

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

      get "already_active_at_school", action: :new
      get "induction-completed", action: :new
      get "induction-exempt", action: :new

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

      get "programme-type", action: :new
      post "programme-type", action: :create
      get "change-programme-type", action: :new
      post "change-programme-type", action: :create
      get "no-previous-ect-choices-change-programme-type", action: :new
      post "no-previous-ect-choices-change-programme-type", action: :create
      get "change-provider-led-programme-type", action: :new
      post "change-provider-led-programme-type", action: :create

      get "lead-provider", action: :new
      post "lead-provider", action: :create
      get "change-lead-provider", action: :new
      post "change-lead-provider", action: :create
      get "no-previous-ect-choices-change-lead-provider", action: :new
      post "no-previous-ect-choices-change-lead-provider", action: :create
      get "programme-type-change-lead-provider", action: :new
      post "programme-type-change-lead-provider", action: :create

      get "working-pattern", action: :new
      post "working-pattern", action: :create
      get "change-working-pattern", action: :new
      post "change-working-pattern", action: :create

      get "use-previous-ect-choices", action: :new
      post "use-previous-ect-choices", action: :create
      get "change-use-previous-ect-choices", action: :new
      post "change-use-previous-ect-choices", action: :create

      get "check-answers", action: :new
      post "check-answers", action: :create

      get "cant-use-email", action: :new
      post "cant-use-email", action: :create

      get "confirmation", action: :new
    end
  end

  namespace :schools, path: :school do
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

      get "cant-use-changed_email", action: :new
      post "cant-use-changed_email", action: :create
      get "cant-use-email", action: :new
      post "cant-use-email", action: :create

      get "review-mentor-eligibility", action: :new
      post "review-mentor-eligibility", action: :create

      get "check-answers", action: :new
      post "check-answers", action: :create

      get "confirmation", action: :new
    end
  end

  namespace :api do
    namespace :v3 do
      resources :participants, only: %i[index show] do
        put :change_schedule, path: "change-schedule"
        put :defer
        put :resume
        put :withdraw
        get :transfers, to: "transfers#show"

        collection do
          resources :transfers, only: %i[index]
        end
      end

      resources :declarations, only: %i[create show index] do
        put :void, path: "void"
      end

      resources :statements, only: %i[index show]
      resources :delivery_partners, only: %i[index show], path: "delivery-partners"
      resources :partnerships, only: %i[show index create update]
      resources :schools, only: %i[index show]
      resources :unfunded_mentors, only: %i[index show], path: "unfunded-mentors"
    end
  end
end
