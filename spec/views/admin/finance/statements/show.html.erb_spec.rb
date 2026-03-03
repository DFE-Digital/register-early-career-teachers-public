RSpec.describe "admin/finance/statements/show.html.erb" do
  let!(:contract_period) { FactoryBot.create(:contract_period) }
  let!(:active_lead_provider) do
    FactoryBot.create(
      :active_lead_provider,
      lead_provider: FactoryBot.create(:lead_provider, name: "Some LP"),
      contract_period:
    )
  end

  let(:banded_fee_structure) do
    FactoryBot.create(:contract_banded_fee_structure, :with_bands)
  end
  let(:contract) do
    FactoryBot.create(
      :contract,
      contract_trait,
      active_lead_provider:,
      banded_fee_structure:
    )
  end
  let(:contract_trait) { :for_ecf }

  let!(:jan_statement) do
    deadline_date = Date.new(contract_period.year, 1, 1).prev_day
    payment_date = Date.new(contract_period.year, 1, 31)
    FactoryBot.create(
      :statement,
      contract:,
      contract_period:,
      active_lead_provider:,
      deadline_date:,
      payment_date:,
      year: payment_date.year,
      month: payment_date.month
    )
  end
  let!(:feb_statement) do
    deadline_date = Date.new(contract_period.year, 2, 1).prev_day
    payment_date = Date.new(contract_period.year, 2, 28)
    FactoryBot.create(
      :statement,
      contract:,
      contract_period:,
      active_lead_provider:,
      deadline_date:,
      payment_date:,
      year: payment_date.year,
      month: payment_date.month
    )
  end

  let(:ect_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :with_active_lead_provider,
      active_lead_provider:
    )
  end
  let(:mentor_training_period) do
    FactoryBot.create(
      :training_period,
      :for_mentor,
      :with_active_lead_provider,
      active_lead_provider:
    )
  end

  let(:statement) { Admin::StatementPresenter.new(feb_statement) }

  before do
    create_clawback(
      ect_training_period,
      payment_statement: jan_statement,
      clawback_statement: feb_statement
    )
    create_clawback(
      mentor_training_period,
      payment_statement: jan_statement,
      clawback_statement: feb_statement
    )
    assign(:statement, statement)
  end

  def create_clawback(training_period, payment_statement:, clawback_statement:)
    FactoryBot.create(
      :declaration,
      :paid,
      payment_statement:,
      training_period:
    )
    FactoryBot.create(
      :declaration,
      :clawed_back,
      clawback_statement:,
      training_period:
    )
  end

  it "has title with lead provider name and statement month and year" do
    render

    expect(view.content_for(:page_title))
      .to eq("Some LP - February #{contract_period.year}")
  end

  it "displays the statement information in a summary list" do
    render

    expect(rendered).to have_css(".govuk-summary-list")
  end

  context "for `ecf` contracts" do
    let(:contract_trait) { :for_ecf }

    it "displays clawbacks in a single table" do
      render

      expect(rendered).to have_css("table caption", text: "Clawbacks")
    end
  end

  context "for `ittecf_ectp` contracts" do
    let(:contract_trait) { :for_ittecf_ectp }

    it "displays clawbacks in separate tables" do
      render

      expect(rendered).to have_css("table caption", text: "ECT clawbacks")
      expect(rendered).to have_css("table caption", text: "Mentor clawbacks")
    end
  end
end
