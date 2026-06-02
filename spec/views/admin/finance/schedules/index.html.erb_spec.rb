RSpec.describe "admin/finance/schedules/index.html.erb" do
  before do
    assign(:contract_period, contract_period)

    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      "Schedules" => nil
    })
  end

  let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

  it "renders breadcrumbs" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to include("Schedules")
  end

  it "has intro text" do
    render
    expect(rendered).to have_text(/Manage schedules for the \d{4} contract period./)
  end

  context "when a contract period is closed to amendments" do
    it "disables the add schedule button" do
      render
      expect(rendered).to have_button("Add schedule", disabled: true)
    end
  end

  context "when a contract period is open to amendments" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    it "has an add schedule button" do
      render
      expect(rendered).to have_link("Add schedule")
    end
  end

  context "when the current contract period has all possible schedules" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    before do
      Schedule.identifiers.each_value do |identifier|
        FactoryBot.create(:schedule, identifier:, contract_period:)
      end
    end

    it "disables the add schedule button" do
      render
      expect(rendered).to have_button("Add schedule", disabled: true)
    end
  end

  context "when a new contract period is opened" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    it "has no schedules" do
      render
      expect(rendered).to have_text("This contract period currently has no schedules.")
    end
  end

  context "when the contract period has schedules" do
    before do
      FactoryBot.create(:schedule, identifier: "ecf-reduced-april", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-standard-april", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-standard-january", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-extended-september", contract_period:)
    end

    it "lists their names by type then month chronologically" do
      render
      expect(rendered).not_to have_text("This contract period currently has no schedules.")
      expect(rendered).to have_text("Standard January")
      expect(rendered).to have_text("Standard April")
      expect(rendered).to have_text("Reduced April")
      expect(rendered).to have_text("Extended September")
    end
  end
end
