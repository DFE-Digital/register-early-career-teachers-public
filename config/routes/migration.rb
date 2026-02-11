namespace :migration do
  resources :migrations, only: %i[index create], path: "/" do
    collection do
      get "cache_stats", action: :cache_stats, as: :cache_stats
      get "download_report/:model", action: :download_report, as: :download_report
      post "reset", action: :reset, as: :reset
    end
  end

  resources :failures, only: %i[index]
  resources :model_failures, path: "migrator-failures", only: %i[index]
  resources :teacher_failures, path: "teacher-failures", only: %i[index]
  resources :teachers, only: %i[index show]
  resource :legacy_profile_gantt, only: :show, controller: "legacy_profile_gantt"
  resource :new_gantt, only: :show, controller: "new_gantt"
  get "download-induction-records", action: :download, controller: :induction_record_export
  get "download-failed-combinations", action: :download, controller: :failed_combinations_export
  get "download-teacher-combinations", action: :download, controller: :teacher_combinations_export
  get "download-detected-ecf1-combinations", action: :download, controller: :detected_ecf1_combinations_export
  get "download-ecf2-migrated-combinations", action: :download, controller: :ecf2_migrated_combinations_export
  get "download-detected-ecf1-mentorships", action: :download, controller: :detected_ecf1_mentorships_export
  get "download-ecf2-migrated-mentorships", action: :download, controller: :ecf2_migrated_mentorships_export
  get "download-failed-mentorships", action: :download, controller: :failed_mentorships_export

  constraints -> { Rails.application.config.parity_check[:enabled] } do
    resources :parity_checks, path: "parity-checks", only: %i[new create show], param: :run_id do
      collection do
        get :completed
      end

      resources :requests, only: :show, module: :parity_checks
      resources :responses, only: :show, module: :parity_checks
    end
  end
end
