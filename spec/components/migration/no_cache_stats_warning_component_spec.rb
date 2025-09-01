RSpec.describe Migration::NoCacheStatsWarningComponent, type: :component do
  it "renders no statistics are available message" do
    render_inline(described_class.new)

    expect(page).to have_content("No cache statistics are available for the completed migrations.")
  end
end
