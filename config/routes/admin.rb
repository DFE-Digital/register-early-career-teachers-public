get "/admin", to: redirect("admin/teachers")

namespace :admin do
  resource :impersonate, only: %i[create destroy], controller: "impersonation"

  constraints -> { Rails.application.config.enable_blazer } do
    mount Blazer::Engine, at: "blazer"
  end

  # Background jobs dashboard
  mount MissionControl::Jobs::Engine, at: "jobs"

  resources :users
  resources :batches, only: %i[index], path: "bulk" # all activity

  resources :organisations, only: %i[index] do
    collection do
      resources :appropriate_bodies, only: %i[index show], path: "appropriate-bodies" do
        scope module: :appropriate_bodies do
          resource :timeline, only: :show
          resources :current_ects, only: :index, path: "current-ects"
          resources :batches, only: %i[index show]
        end
      end

      resources :lead_providers, only: %i[index], path: "lead-providers"
      resources :delivery_partners, only: %i[index show edit update], path: "delivery-partners" do
        resource :delivery_partnerships, only: %i[new create], path: ":year", as: :delivery_partnership, controller: "delivery_partners/delivery_partnerships"
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

  resources :teachers, only: %i[show index] do
    scope module: :teachers do
      resource :induction, only: %i[show]
      resource :school, only: %i[show]
      resource :training, only: %i[show]
      resources :declarations, only: %i[index]
      resources :training_periods, only: [], path: "training-periods" do
        resource :partnership, only: %i[new create], controller: :training_partnerships do
          get :no_other_partnerships, path: "no-other-partnerships"
        end
      end
    end
    resources :induction_periods, only: %i[new create edit update destroy], path: "induction-periods" do
      member do
        get :confirm_delete, path: "confirm-delete"
      end
    end

    scope module: :teachers do
      resource :timeline, only: :show, controller: :timeline
      resource :record_passed_outcome, only: %i[new create show], path: "record-passed-outcome", controller: :record_passed_induction
      resource :record_failed_outcome, only: %i[new create show], path: "record-failed-outcome", controller: :record_failed_induction
      resource :reopen_induction, only: :update, path: "reopen-induction", controller: :reopen_induction do
        member { get :confirm }
      end
      resources :extensions, except: :show do
        member { get :confirm_delete }
      end
    end
  end

  namespace :import_ect, path: "import-ect" do
    resource :find_ect, only: %i[new create], path: "find-ect", as: "find", controller: :find_ect
    resources :check_ect, only: %i[edit update], path: "check-ect", as: "check"
    resources :register_ect, only: %i[show], path: "register-ect", as: "register"
  end

  resource :finance, only: :show, controller: :finance do
    scope module: :finance do
      collection do
        resources :statements, as: "finance_statements", only: %i[index show] do
          collection { post :choose }
          member { post :authorise_payment }

          resources :adjustments, only: %i[new create edit update destroy] do
            member { get :delete }
          end
        end
      end
    end
  end
end
