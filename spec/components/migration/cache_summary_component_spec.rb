RSpec.describe Migration::CacheSummaryComponent, type: :component do
  let(:combined_stats) do
    {
      cache_hits: { schools: 90, teachers: 10 },
      cache_misses: { schools: 10, teachers: 0 }
    }
  end

  it "renders the cache summary panels" do
    render_inline(described_class.new(combined_stats:))

    expect(page).to have_content("Total Cache Hits")
    expect(page).to have_content("100")
    expect(page).to have_content("Total Cache Misses")
    expect(page).to have_content("10")
  end

  it "renders the overall hit rate" do
    render_inline(described_class.new(combined_stats:))

    expect(page).to have_content("Overall Cache Hit Rate:")
    expect(page).to have_content("90.9%")
  end

  it "applies correct colour based on hit rate" do
    render_inline(described_class.new(combined_stats:))

    expect(page).to have_css(".govuk-tag--green")
  end
end
