RSpec.describe Migration::DataMigrationPerformanceTableComponent, type: :component do
  let(:data_migration) do
    double(
      "DataMigration",
      model: "schools",
      worker: 0,
      cache_stats: {
        hit_rates: {
          overall: 90.9
        },
        total_hits: 100,
        total_misses: 10,
        cache_hits: {
          schools: 50,
          teachers: 50
        },
        cache_misses: {
          schools: 5,
          teachers: 5
        }
      }
    )
  end

  let(:data_migrations) { [data_migration] }

  it "renders the data migration performance table" do
    render_inline(described_class.new(data_migrations:))

    expect(page).to have_content("DataMigration Cache Performance")
    expect(page).to have_content("Schools")
    expect(page).to have_content("Worker 0")
    expect(page).to have_content("100")
    expect(page).to have_content("10")
    expect(page).to have_content("90.9%")
    expect(page).to have_content("Schools, Teachers")
  end

  it "applies correct hit rate colours" do
    render_inline(described_class.new(data_migrations:))

    expect(page).to have_css(".govuk-tag--green", text: "90.9%")
  end
end
