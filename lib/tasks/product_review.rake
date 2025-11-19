namespace :product_review do
  desc "Reset pre-production TRS data"
  task reset_trs: :environment do
    abort("Only available for genuine API calls") if Rails.application.config.enable_fake_trs_api
    abort("Only available for test deployments") unless Rails.application.config.enable_test_guidance && Rails.application.config.enable_personas
    abort("Only available for pre-production TRS") unless Rails.application.config.trs_api_base_url.include?("preprod")

    api_client = TRS::APIClient.build
    file_path = Rails.root.join("spec/fixtures/seeds_trs.csv")

    CSV.foreach(file_path, headers: true) do |row|
      _name, trn, _dob, _ni_number, status = row.to_h.values
      api_client.reset_teacher_induction!(trn:) if status.eql?("RequiredToComplete")
    end
  end
end
