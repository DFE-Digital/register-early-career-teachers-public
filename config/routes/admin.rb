get '/admin', to: redirect('admin/teachers')

namespace :admin do
  resource :impersonate, only: %i[create destroy], controller: 'impersonation'

  constraints -> { Rails.application.config.enable_blazer } do
    mount Blazer::Engine, at: "blazer"
  end

  # Background jobs dashboard
  mount MissionControl::Jobs::Engine, at: "jobs"

  resources :users, only: %i[index]
  resources :batches, only: %i[index], path: 'bulk' # all activity

  resources :organisations, only: %i[index] do
    collection do
      resources :appropriate_bodies, only: %i[index show], path: 'appropriate-bodies' do
        scope module: :appropriate_bodies do
          resource :timeline, only: :show
          resources :current_ects, only: :index, path: 'current-ects'
          resources :batches, only: %i[index show]
        end
      end

      resources :lead_providers, only: %i[index], path: 'lead-providers'
      resources :delivery_partners, only: %i[index show edit update], path: 'delivery-partners' do
        resource :delivery_partnerships, only: %i[new create], path: ':year', as: :delivery_partnership, controller: 'delivery_partners/delivery_partnerships'
      end
    end
  end

  resources :schools, only: %i[index show], param: :urn do
    scope module: :schools do
      resource :overview, only: :show
      resource :teachers, only: :show
      resource :partnerships, only: :show
    end
  end

  resources :teachers, only: %i[index show] do
    resource :timeline, only: %i[show], controller: 'teachers/timeline'
    resources :induction_periods, only: %i[new create edit update destroy], path: 'induction-periods' do
      member do
        get :confirm_delete, path: 'confirm-delete'
      end
    end
    resource :record_passed_outcome, only: %i[new create show], path: 'record-passed-outcome', controller: 'teachers/record_passed_outcome'
    resource :record_failed_outcome, only: %i[new create show], path: 'record-failed-outcome', controller: 'teachers/record_failed_outcome'
    resource :reopen_induction, only: %i[update], path: 'reopen-induction', controller: 'teachers/reopen_induction' do
      member { get :confirm }
    end
    resources :extensions, only: %i[index new create edit update destroy], controller: 'teachers/extensions' do
      member do
        get :confirm_delete
      end
    end
  end

  namespace :import_ect, path: 'import-ect' do
    resource :find_ect, only: %i[new create], path: 'find-ect', controller: 'find_ect', as: 'find'
    resources :check_ect, only: %i[edit update], path: 'check-ect', controller: 'check_ect', as: 'check'
    resources :register_ect, only: %i[show], path: 'register-ect', controller: 'register_ect', as: 'register'
  end

  resource :finance, only: %i[show], controller: 'finance' do
    collection do
      resources :statements, as: 'finance_statements', controller: 'finance/statements', only: %i[index show] do
        collection do
          post :choose
        end
        member do
          post :authorise_payment
        end
        resources :adjustments, controller: 'finance/adjustments', only: %i[new create edit update destroy] do
          member do
            get :delete
          end
        end
      end
    end
  end
end
