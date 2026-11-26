RSpec.shared_context "with seeds" do |seed_files|
  before do
    Rails.root.glob("db/seeds/support/{*.rb,builders/*.rb}").each { require(it) }

    seed_files.each do |seed_file|
      ApplicationRecord.transaction { load Rails.root.join("db/seeds/#{seed_file}.rb") }
    end
  end
end
