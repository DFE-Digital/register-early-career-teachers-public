RSpec.describe "admin/finance/schedules/index.html.erb" do
  before do
    assign(:contract_period, contract_period)
  end

  let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

  it "has intro text" do
    render
    expect(rendered).to have_text(/Manage schedules for the \d{4} contract period./)
  end

  context "when a contract period is closed to amendments" do
    it "has a disabled add schedule button" do
      render
      expect(rendered).to have_button("Add schedule", disabled: true)
    end
  end

  context "when a contract period is open to amendments" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    it "has an enabled add a schedule button" do
      render
      expect(rendered).to have_button("Add schedule", disabled: false)
    end
  end

  context "when the current contract period has all possible schedules" do
    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    before do
      Schedule.identifiers.each_value do |identifier|
        FactoryBot.create(:schedule, identifier:, contract_period:)
      end
    end

    it "has a disabled add schedule button" do
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
      FactoryBot.create(:schedule, identifier: "ecf-standard-january", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-reduced-april", contract_period:)
    end

    it "lists their names" do
      render
      expect(rendered).not_to have_text("This contract period currently has no schedules.")
      expect(rendered).to have_text("Standard January")
      expect(rendered).to have_text("Reduced April")
    end
  end
end
