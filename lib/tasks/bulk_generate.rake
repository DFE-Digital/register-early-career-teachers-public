namespace :bulk do
  desc "Generate pre-prod CSV fixtures"
  task generate: :environment do
    BulkGenerate.new.call
  end
end
