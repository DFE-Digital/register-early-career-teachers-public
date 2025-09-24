Rails.application.routes.draw do
  # DFE-Digital/dfe-wizard auto-routing
  concern :wizardable do |options = {}|
    options[:wizard]::Wizard.steps.first.each_key do |step|
      path = step.to_s.dasherize

      get path, action: :new
      post path, action: :create
    end
  end

  root to: 'pages#home'
  get '/support', to: 'pages#support'
  get '/cookies', to: 'pages#cookies'
  get '/accessibility', to: 'pages#accessibility'
  get '/privacy', to: 'pages#privacy'
  get '/school-requirements', to: 'pages#school_requirements'
  get '/healthcheck', to: 'health_check#show', as: :rails_health_check

  scope via: :all do
    get '/404', to: 'errors#not_found'
    get '/422', to: 'errors#unprocessable_content'
    get '/429', to: 'errors#too_many_requests'
    get '/500', to: 'errors#internal_server_error'
  end

  # omniauth sign-in
  get '/auth/:provider/callback', to: 'sessions#create'
  post '/auth/:provider/callback', to: 'sessions#create'
  get '/sign-in', to: 'sessions#new'
  get '/sign-out', to: 'sessions#destroy'
  get '/switch-role', to: 'sessions#update', as: 'switch_role'

  # one time password
  get '/otp-sign-in', to: 'otp_sessions#new'
  post '/otp-sign-in', to: 'otp_sessions#create'
  get '/otp-sign-in/code', to: 'otp_sessions#request_code'
  post '/otp-sign-in/verify', to: 'otp_sessions#verify_code'

  constraints -> { Rails.application.config.enable_personas } do
    resources 'personas', only: %i[index]
  end

  draw :admin
  draw :appropriate_body
  draw :school
  draw :schools
  draw :migration
  draw :api
end
