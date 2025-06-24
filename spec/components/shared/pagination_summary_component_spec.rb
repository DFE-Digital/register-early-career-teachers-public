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
end
