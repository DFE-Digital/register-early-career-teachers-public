RSpec.describe "admin/finance/milestones/new.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
  let(:milestone) { Milestone.new }

  before do
    assign(:contract_period, contract_period)
    assign(:schedule, schedule)
    assign(:milestone, milestone)
  end

  it "has the correct page title" do
    render
    expect(view.content_for(:page_title)).to eq("Add milestone")
  end

  it "renders the caption with the schedule name and contract period year" do
    render
    expect(view.content_for(:page_caption)).to have_css(".govuk-caption-l", text: "#{schedule.name} #{contract_period.year}")
  end

  it "has a back link to the schedule page" do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_contract_period_schedule_path(contract_period, schedule))
  end

  it "renders a form with radio buttons for available declaration types" do
    render
    expect(rendered).to have_css(".govuk-radios")

    schedule.available_milestones.take(3).each do |declaration_type|
      expect(rendered).to have_css("input[type='radio'][value='#{declaration_type}']")
      expect(rendered).to have_text(declaration_type.titleize)
    end
  end

  it "has start date fields" do
    render
    expect(rendered).to have_field("milestone[start_date(3i)]")
    expect(rendered).to have_field("milestone[start_date(2i)]")
    expect(rendered).to have_field("milestone[start_date(1i)]")
  end

  it "has milestone date fields" do
    render
    expect(rendered).to have_field("milestone[milestone_date(3i)]")
    expect(rendered).to have_field("milestone[milestone_date(2i)]")
    expect(rendered).to have_field("milestone[milestone_date(1i)]")
  end

  it "has a submit button" do
    render
    expect(rendered).to have_button("Save")
  end

  it "has a cancel link" do
    render
    expect(rendered).to have_link("Cancel and return to schedule", href: admin_contract_period_schedule_path(contract_period, schedule))
  end

  context "when there are no available milestones" do
    before do
      Milestone.declaration_types.each_value do |declaration_type|
        FactoryBot.create(:milestone, schedule:, declaration_type:)
      end
    end

    it "renders an empty radio button fieldset" do
      render
      expect(rendered).to have_css(".govuk-radios")
      expect(rendered).not_to have_css(".govuk-radios__item")
    end
  end

  context "when the milestone has validation errors" do
    let(:milestone) do
      Milestone.new.tap do |m|
        m.errors.add(:start_date, "Enter a start date")
        m.errors.add(:declaration_type, "Select a declaration type")
      end
    end

    it "prefixes the page title with 'Error:'" do
      render
      expect(view.content_for(:page_title)).to start_with("Error:")
    end

    it "renders an error summary" do
      render
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end

    it "has error styling on the form group" do
      render
      expect(rendered).to have_css(".govuk-form-group--error")
    end
  end
end
