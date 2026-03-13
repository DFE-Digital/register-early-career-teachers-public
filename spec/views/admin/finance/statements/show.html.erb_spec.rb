RSpec.describe "admin/finance/statements/show.html.erb" do
  let(:contract_trait) { :for_ecf }
  let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:contract) do
    FactoryBot.create(
      :contract,
      contract_trait,
      active_lead_provider:,
      banded_fee_structure:
    )
  end

  let(:banded_fee_structure) do
    FactoryBot.create(:contract_banded_fee_structure, :with_bands)
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Some LP") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:feb_statement_fee_type) { :output_fee }

  let!(:jan_statement) do
    deadline_date = Date.new(contract_period.year, 1, 1).prev_day
    payment_date = Date.new(contract_period.year, 1, 31)
    FactoryBot.create(
      :statement,
      :output_fee,
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
    FactoryBot.create(
      :statement,
      feb_statement_fee_type,
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
  let(:deadline_date) { Date.new(contract_period.year, 2, 1).prev_day }
  let(:payment_date) { Date.new(contract_period.year, 2, 28) }

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

  it "has title with lead provider name and statement details" do
    render

    expect(rendered).to have_css(".govuk-caption-l", text: "Some LP")
    expect(rendered).to have_css(".govuk-heading-m", text: "February 2025")

    expect(rendered).to have_css(".govuk-heading-m", text: "28 February 2025")
    expect(rendered).to have_css(".govuk-heading-m", text: "31 January 2025")
    expect(rendered).to have_css(".govuk-table", text: "VAT")
  end

  context "when the statement is payable" do
    let!(:feb_statement) do
      FactoryBot.create(
        :statement,
        :payable,
        contract:,
        contract_period:,
        active_lead_provider:,
        deadline_date:,
        payment_date:,
        year: payment_date.year,
        month: payment_date.month
      )
    end

    around do |example|
      travel_to(payment_date) do
        example.run
      end
    end

    it "displays the Authorise for payment button" do
      render

      expect(rendered).to have_link("Authorise for payment", href: new_admin_finance_statement_authorisation_path(statement))
    end
  end

  it "displays provider targets" do
    render

    expect(rendered).to have_css("details", text: "Provider targets (per academic year)")
  end

  context "when the statement is for an ECF contract" do
    let(:contract_trait) { :for_ecf }

    it "displays the ECF payment overview component" do
      render

      expect(rendered).to have_text("Uplift fees")
      expect(rendered).to have_text("Output payment")
      expect(rendered).to have_text("Clawbacks")

      expect(rendered).not_to have_text("ECTs output payment")
      expect(rendered).not_to have_text("Mentors output payment")
      expect(rendered).not_to have_text("ECTs clawbacks")
      expect(rendered).not_to have_text("Mentors clawbacks")
    end

    it "displays clawbacks in a single table" do
      render

      expect(rendered).to have_css("table caption", text: "Clawbacks")
    end
  end

  context "when the statement is for an ITTECF ECTP contract" do
    let(:contract_trait) { :for_ittecf_ectp }

    it "displays the ITTECF ECTP payment overview component" do
      render

      expect(rendered).to have_text("ECTs output payment")
      expect(rendered).to have_text("Mentors output payment")
      expect(rendered).to have_text("ECTs clawbacks")
      expect(rendered).to have_text("Mentors clawbacks")

      expect(rendered).not_to have_text("Uplift fees")
      expect(rendered).not_to have_text("Output payment")
      expect(rendered).not_to have_text("Clawbacks")
    end

    it "displays clawbacks in separate tables" do
      render

      expect(rendered).to have_css("table caption", text: "ECT clawbacks")
      expect(rendered).to have_css("table caption", text: "Mentor clawbacks")
    end
  end

  it "displays the adjustments in a table" do
    render

    expect(rendered).to have_css("table caption", text: "Additional adjustments")
  end
end
