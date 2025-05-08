namespace :bulk do
  desc "Generate fake CSV fixtures"
  task generate: :environment do
    BulkGenerate.new.call
  end
end
