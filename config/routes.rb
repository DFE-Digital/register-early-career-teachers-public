Rails.application.routes.draw do
  root to: 'pages#home'
  get '/support', to: 'pages#support'

  get "healthcheck" => "rails/health#show", as: :rails_health_check

  scope via: :all do
    get '/404', to: 'errors#not_found'
    get '/422', to: 'errors#unprocessable_entity'
    get '/429', to: 'errors#too_many_requests'
    get '/500', to: 'errors#internal_server_error'
  end

  resources :cities, only: %i[index create show]

  # omniauth sign-in
  get 'auth/:provider/callback', to: 'sessions#create'
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

  post 'auth/:provider/callback', to: 'sessions#create'

  get '/admin', to: 'admin/teachers#index'

  namespace :admin do
    constraints -> { Rails.application.config.enable_blazer } do
      mount Blazer::Engine, at: "blazer"
    end

    resources :users, only: %i[index] do
    end

    resources :organisations, only: %i[index] do
    end

    resources :appropriate_bodies, only: %i[index], path: 'appropriate-bodies' do
    end

    resources :schools, only: %i[index show], param: :urn do
    end

    resources :teachers, only: %i[index show] do
      resources :induction_periods, only: %i[edit update], path: 'induction-periods'
    end
  end

  resource :appropriate_bodies, only: %i[show], path: 'appropriate-body', as: 'ab_landing', controller: 'appropriate_bodies/landing'
  namespace :appropriate_bodies, path: 'appropriate-body', as: 'ab' do
    resources :teachers, only: %i[show index], controller: 'teachers', param: 'trn' do
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
        get 'exempt/:id', to: '/appropriate_bodies/claim_an_ect/errors#exempt', as: 'exempt'
        get 'completed/:id', to: '/appropriate_bodies/claim_an_ect/errors#completed', as: 'completed'
      end
    end
  end

  namespace :migration do
    resources :migrations, only: %i[index create], path: "/" do
      collection do
        get ":model/failures", to: "failures#index", as: :failures
        get "download_report/:model", action: :download_report, as: :download_report
        post "reset", action: :reset, as: :reset
      end
    end
    resources :teachers, only: %i[index show]
  end

  namespace :schools do
    get "/home/ects", to: "home#index", as: :ects_home

    namespace :register_ect_wizard, path: "register-ect" do
      get "what-you-will-need", as: :start, action: :start

      get "find-ect", action: :new
      post "find-ect", action: :create

      get "national-insurance-number", action: :new
      post "national-insurance-number", action: :create

      get "trn-not-found", action: :new
      get "not-found", action: :new

      get "already_active_at_school", action: :new
      get "induction-completed", action: :new
      get "induction-exempt", action: :new

      get "review-ect-details", action: :new
      post "review-ect-details", action: :create

      get "email-address", action: :new
      post "email-address", action: :create

      get "start-date", action: :new
      post "start-date", action: :create

      get "state-school-appropriate-body", action: :new
      post "state-school-appropriate-body", action: :create

      get "independent-school-appropriate-body", action: :new
      post "independent-school-appropriate-body", action: :create

      get "programme-type", action: :new
      post "programme-type", action: :create

      get "working-pattern", action: :new
      post "working-pattern", action: :create

      get "check-answers", action: :new
      post "check-answers", action: :create

      get "confirmation", action: :new
    end
  end

  namespace :schools, path: :school do
    resources :ects, only: [] do
      resource :mentorship, only: %i[new create] do
        get :confirmation, on: :collection
      end
    end

    namespace :register_mentor_wizard, path: "register-mentor" do
      get "what-you-will-need", as: :start, action: :start

      get "find-mentor", action: :new
      post "find-mentor", action: :create

      get "national-insurance-number", action: :new
      post "national-insurance-number", action: :create

      get "no-trn", action: :new
      get "trn-not-found", action: :new
      get "not-found", action: :new

      get "already-active-at-school", action: :new
      post "already-active-at-school", action: :create

      get "review-mentor-details", action: :new
      post "review-mentor-details", action: :create

      get "email-address", action: :new
      post "email-address", action: :create

      get "check-answers", action: :new
      post "check-answers", action: :create

      get "confirmation", action: :new
    end
  end
end
