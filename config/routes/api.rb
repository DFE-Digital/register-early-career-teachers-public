constraints -> { Rails.application.config.enable_api } do
  namespace :api do
    get "guidance", to: "guidance#show"
    resources :release_notes, path: "guidance/release-notes", only: %i[index show], param: :slug, as: :guidance_release_notes
    get "guidance/*page", to: "guidance#page", as: :guidance_page
    get "docs/:version", to: "documentation#index", as: :documentation

    namespace :v3 do
      resources :participants, only: %i[index show], param: :api_id do
        member do
          put :change_schedule, path: "change-schedule"
          put :defer
          put :resume
          put :withdraw
          get :transfers, to: "transfers#show"
        end

        collection do
          resources :transfers, only: %i[index]
        end
      end

      resources :declarations, only: %i[create show index] do
        put :void, path: "void"
      end

      resources :statements, only: %i[index show], param: :api_id
      resources :delivery_partners, only: %i[index show], path: "delivery-partners", param: :api_id
      resources :partnerships, only: %i[show index create update], param: :api_id
      resources :schools, only: %i[index show], param: :api_id
      resources :unfunded_mentors, only: %i[index show], path: "unfunded-mentors", param: :api_id
    end
  end
end
