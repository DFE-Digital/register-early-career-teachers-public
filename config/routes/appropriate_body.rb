resource :appropriate_bodies, only: %i[show], path: 'appropriate-body', as: 'ab_landing', controller: 'appropriate_bodies/landing'

namespace :appropriate_bodies, path: 'appropriate-body', as: 'ab' do
  resources :teachers, only: %i[show index], controller: 'teachers' do
    match 'closed', to: 'teachers#index', via: :get, on: :collection, as: 'closed', defaults: { status: 'closed' }
    match 'open', to: 'teachers#index', via: :get, on: :collection, as: 'open', defaults: { status: 'open' }

    resource :release_ect, only: %i[new create show], path: 'release', controller: 'teachers/release_ect'
    resource :record_passed_outcome, only: %i[new create show], path: 'record-passed-outcome', controller: 'teachers/record_passed_outcome'
    resource :record_failed_outcome, only: %i[new create show], path: 'record-failed-outcome', controller: 'teachers/record_failed_outcome'

    resources :induction_periods, only: %i[edit update], path: 'induction-periods'
    resources :extensions, controller: 'teachers/extensions', only: %i[show edit update index new create]
    resources :initial_teacher_training_records, path: 'itt-data', controller: 'teachers/initial_teacher_training_records', only: :index
  end

  namespace :claim_an_ect, path: 'claim-an-ect' do
    resource :find_ect, only: %i[new create], path: 'find-ect', controller: 'find_ect', as: 'find'
    resources :check_ect, only: %i[edit update], path: 'check-ect', controller: 'check_ect', as: 'check'
    resources :register_ect, only: %i[edit update show], path: 'register-ect', controller: 'register_ect', as: 'register'
  end

  namespace :process_batch, path: 'bulk', as: 'batch' do
    resources :claims, format: %i[html csv]
    resources :actions, format: %i[html csv]
  end
end
