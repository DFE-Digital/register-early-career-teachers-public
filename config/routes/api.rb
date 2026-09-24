namespace :api do
  # legacy documentation routes, can be removed with LP API v3
  get "guidance", to: redirect("/api/docs/training/guidance")
  get "guidance/release-notes", to: redirect("/api/docs/training/guidance/release-notes")
  get "guidance/release-notes/:slug", to: redirect("/api/docs/training/guidance/release-notes/%{slug}")
  get "guidance/swagger-api-documentation", to: redirect("/api/docs/training/v3")
  get "guidance/*page", to: redirect("/api/docs/training/guidance/%{page}")
  get "docs/v3", to: redirect("/api/docs/training/v3")

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

    resources :declarations, only: %i[create show index], param: :api_id, path: "participant-declarations" do
      member { put :void, path: "void" }
    end

    resources :statements, only: %i[index show], param: :api_id
    resources :delivery_partners, only: %i[index show], path: "delivery-partners", param: :api_id
    resources :partnerships, only: %i[show index create update], param: :api_id
    resources :schools, only: %i[index show], param: :api_id
    resources :unfunded_mentors, only: %i[index show], path: "unfunded-mentors", param: :api_id
  end

  constraints -> { Rails.application.config.enable_apis_under_development } do
    get "docs", to: "documentation#show", as: :documentation
  end

  namespace :docs, module: :documentation do
    scope "training", module: :training, as: :training do
      get "guidance", to: "guidance#show"

      scope "guidance" do
        resources :release_notes,
                  path: "release-notes",
                  only: %i[index show],
                  param: :slug,
                  as: :guidance_release_notes

        get "*page", to: "guidance#page", as: :guidance_page
      end

      get "v3", to: "v3/documentation#index", as: :documentation
    end
  end
end

constraints -> { Rails.application.config.enable_apis_under_development } do
  namespace :oauth, module: "api/oauth" do
    get "authorize", to: "authorizations#new", as: :authorization
    post "authorize", to: "authorizations#create"
    delete "authorize", to: "authorizations#destroy"
    post "token", to: "authorizations/access_tokens#create", as: :access_token
    post "revoke", to: "authorizations/revocations#create", as: :revocation
  end
end
