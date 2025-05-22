namespace :bulk do
  desc "Generate pre-prod CSV fixtures"
  task generate: :environment do
    # TODO: silence Faraday logging
    Rails.logger.silence do
      BulkGenerate.new.call(verbose: true)
    end
  end
end
