RSpec.describe Migration::CachePerformanceTableComponent, type: :component do
  let(:combined_stats) do
    {
      cache_hits: {schools: 90, teachers: 10},
      cache_misses: {schools: 10, teachers: 0},
      cache_loads: {schools: 1, teachers: 1}
    }
  end

  it "renders the cache performance table" do
    render_inline(described_class.new(combined_stats:))

    expect(page).to have_content("Cache Performance")
    expect(page).to have_content("schools")
    expect(page).to have_content("teachers")
    expect(page).to have_content("100")
    expect(page).to have_content("10")
  end

  it "displays correct hit rate colours" do
    render_inline(described_class.new(combined_stats:))

    expect(page).to have_css(".govuk-tag--green", text: "90.0%")
    expect(page).to have_css(".govuk-tag--green", text: "100.0%")
  end
end
