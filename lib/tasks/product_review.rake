# To be run via a GitHub workflow via the staging deployment
# and updates the TRS API (pre-prod)
namespace :product_review do
  desc 'Reset pre-production TRS data'
  task reset_trs: :environment do
    # Safe-guard running under the correct conditions
    abort('Only available for genuine API calls') if Rails.application.config.enable_fake_trs_api
    abort('Only available for test deployments') unless Rails.application.config.enable_test_guidance && Rails.application.config.enable_personas
    abort('Only available for pre-production TRS') unless Rails.application.config.trs_api_base_url.include?('preprod')

    api_client = TRS::APIClient.build
    file_path = Rails.root.join('spec/fixtures/seeds_trs.csv')

    CSV.foreach(file_path, headers: true) do |row|
      _name, trn, _dob, _ni_number, status, qts_awarded = row.to_h.values

      start_date = Date.parse(qts_awarded) + 1.day unless status.in?(%w[None Exempt])
      completed_date = start_date + 1.year unless status.in?(%w[RequiredToComplete InProgress None Exempt])

      api_client.send(:update_induction_status,
                      trn:,
                      status:,
                      modified_at: Time.zone.now,
                      start_date: start_date&.iso8601,
                      completed_date: completed_date&.iso8601)
    end
  end
end
