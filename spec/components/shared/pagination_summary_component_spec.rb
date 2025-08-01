RSpec.describe Shared::PaginationSummaryComponent, type: :component do
  subject { render_inline(component) }

  let(:pagy) { Pagy.new(count: 196, limit: 20, page: 3) }
  let(:component) { described_class.new pagy:, record_name: "users" }

  before do
    allow(component).to receive(:govuk_pagination).and_return("govuk_pagination component")
  end

  it "renders count" do
    expect(subject).to have_content("Showing 41 to 60 of 196 users")
  end

  it "renders pagination" do
    expect(subject).to have_content("govuk_pagination component")
  end

  describe "default values" do
    let(:component) { described_class.new pagy: }

    it "renders count" do
      expect(subject).to have_content("Showing 41 to 60 of 196 records")
    end
  end

  describe "only 1 page" do
    let(:pagy) { Pagy.new(count: 5, limit: 20, page: 1) }

    it "does not render" do
      expect(subject).not_to have_content("Showing")
      expect(subject).not_to have_content("govuk_pagination component")
    end
  end
end
