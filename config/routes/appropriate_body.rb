namespace :appropriate_bodies, path: 'appropriate-body', as: :ab do
  resource :landing, only: :show, path: "", controller: :landing

  resources :teachers, only: %i[show index] do
    match 'closed', to: 'teachers#index', via: :get, on: :collection, as: 'closed', defaults: { status: 'closed' }
    match 'open', to: 'teachers#index', via: :get, on: :collection, as: 'open', defaults: { status: 'open' }

    resources :induction_periods, only: %i[edit update], path: 'induction-periods'

    scope module: :teachers do
      resource :release_ect, only: %i[new create show], path: 'release', controller: :release_ect
      resource :record_passed_outcome, only: %i[new create show], path: 'record-passed-outcome', controller: :record_passed_outcome
      resource :record_failed_outcome, only: %i[new create show], path: 'record-failed-outcome', controller: :record_failed_outcome
      resources :extensions, except: :destroy
      resources :initial_teacher_training_records, path: 'itt-data', only: :index
    end
  end

  namespace :claim_an_ect, path: 'claim-an-ect' do
    resource :find_ect, only: %i[new create], path: 'find-ect', as: 'find', controller: :find_ect
    resources :check_ect, only: %i[edit update], path: 'check-ect', as: 'check'
    resources :register_ect, only: %i[edit update show], path: 'register-ect', as: 'register'
  end

  namespace :process_batch, path: 'bulk', as: 'batch' do
    resources :claims, format: %i[html csv]
    resources :actions, format: %i[html csv]
  end
end
