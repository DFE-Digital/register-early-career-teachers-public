RSpec.describe "admin/appropriate_bodies/show.html.erb" do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name:) }
  let(:name) { "Ancient County Council" }

  before do
    assign(:appropriate_body, appropriate_body_period)
    render
  end

  it "sets the main heading and page title to the appropriate body name" do
    expect(view.content_for(:page_title)).to start_with(appropriate_body_period.name)
    expect(view.content_for(:page_header)).to have_css("h1", text: appropriate_body_period.name)
  end

  context "when the appropriate body name contains ampersands" do
    let(:name) { "Bright Futures Teaching School Hub (Salford & Trafford)" }

    it "does not add the &amp; escape code in the title" do
      expect(view.content_for(:page_title)).to eq name
    end
  end

  context "when the period has no name of its own" do
    let(:teaching_school_hub) do
      FactoryBot.create(:teaching_school_hub, name: "Bright Futures Teaching School Hub")
    end
    let(:appropriate_body_period) do
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub, name: nil, teaching_school_hub:)
    end

    it "heads the page with the parent hub name" do
      expect(view.content_for(:page_header)).to have_css("h1", text: "Bright Futures Teaching School Hub")
    end
  end

  context "when the period is backed by a national body" do
    let(:appropriate_body_period) do
      FactoryBot.create(
        :appropriate_body_period,
        :national,
        name: nil,
        national_body: FactoryBot.create(:national_body, name: "National Body X")
      )
    end

    it "heads the page with the national body name" do
      expect(view.content_for(:page_header)).to have_css("h1", text: "National Body X")
    end
  end

  it "displays the DfE Sign In organisation ID" do
    expect(rendered).to have_css(".govuk-summary-list__value", text: appropriate_body_period.dfe_sign_in_organisation_id)
  end

  it "displays counts of current ECTs and bulk uploads" do
    expect(rendered).to have_css(".govuk-summary-list__value", exact_text: "0", count: 2)
  end
end
