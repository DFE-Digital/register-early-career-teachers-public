RSpec.describe "admin/finance/schedules/new.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2027) }

  before do
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")

    assign(:contract_period, contract_period)
    assign(:schedule, Schedule.new)
  end

  it "has the correct page title" do
    render
    expect(view.content_for(:page_title)).to eq("Add schedule")
  end

  it "renders the caption with the contract period year" do
    render
    expect(view.content_for(:page_caption)).to have_css(".govuk-caption-l", text: "2027 contract period")
  end

  it "has a back link to the schedules index" do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_contract_period_schedules_path(contract_period))
  end

  it "renders a form with radio buttons for only available schedules" do
    render
    expect(rendered).to have_css(".govuk-radios")
    expect(rendered).to have_css(".govuk-radios__item", count: 11)

    expect(rendered).to have_text("Standard April")
    expect(rendered).not_to have_text("Standard January")
  end

  it "has a submit button" do
    render
    expect(rendered).to have_button("Save")
  end

  it "has a cancel link" do
    render
    expect(rendered).to have_link("Cancel and return to schedules", href: admin_contract_period_schedules_path(contract_period))
  end

  context "when the schedule has validation errors" do
    before do
      schedule = Schedule.new
      schedule.errors.add(:identifier, "Select a schedule")
      assign(:schedule, schedule)
    end

    it "prefixes the page title with 'Error:'" do
      render
      expect(view.content_for(:page_title)).to start_with("Error:")
    end

    it "renders an error summary" do
      render
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end
end
