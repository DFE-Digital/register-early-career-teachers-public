RSpec.describe "admin/finance/authorisations/new.html.erb" do
  subject { rendered }

  let(:contract_period) { FactoryBot.create(:contract_period, year:) }
  let(:contract) do
    FactoryBot.create(
      :contract,
      contract_trait,
      active_lead_provider:
    )
  end
  let(:contract_trait) { :for_ecf }

  let(:payment_statement) { FactoryBot.create(:statement, :payable, deadline_date: Date.yesterday, contract:) }
  let(:year) { 2024 }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year:, active_lead_provider:) }
  let(:statement) { Admin::StatementPresenter.new(payment_statement) }
  let(:form) { Admin::Finance::AuthorisePaymentForm.new }
  let!(:declaration) do
    FactoryBot.create(:declaration, :with_ect,
                      declaration_type: "started",
                      payment_status: "payable",
                      school_partnership:,
                      payment_statement:)
  end

  let!(:clawed_back_declaration) do
    FactoryBot.create(:declaration, :with_ect,
                      declaration_type: "started",
                      clawback_status: "awaiting_clawback",
                      school_partnership:,
                      payment_statement:)
  end

  before do
    assign(:statement, statement)
    assign(:form, form)

    render
  end

  it "has the correct title" do
    expect(view.content_for(:page_title)).to eq("Check and authorise statement for payment")
  end

  it "has a back link to the statement" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_finance_statement_path(statement))
  end

  it "has summary information" do
    expect(subject).to have_text(statement.lead_provider_name)
    expect(subject).to have_text(statement.period)
    expect(subject).to have_text(statement.formatted_deadline_date)
    expect(subject).to have_text(statement.formatted_payment_date)
    expect(subject).to have_text("Total")
  end

  it "has a button to authorise the payment, with a tickbox confirmation" do
    expect(subject).to have_field("I confirm I've completed all assurance checks and I authorise payment", type: "checkbox")
    expect(subject).to have_button("Authorise for payment")
  end

  describe "summary table" do
    context "when the statement is for an ECF contract" do
      let(:contract_trait) { :for_ecf }

      it "displays the ECF payment overview component" do
        expect(subject).to have_css("table tr:nth-child(1) td:nth-child(1)", text: "Output payment")
        expect(subject).to have_css("table tr:nth-child(2) td:nth-child(1)", text: "Service fee")
        expect(subject).to have_css("table tr:nth-child(3) td:nth-child(1)", text: "Uplift fees")
        expect(subject).to have_css("table tr:nth-child(4) td:nth-child(1)", text: "Clawbacks")
        expect(subject).to have_css("table tr:nth-child(5) td:nth-child(1)", text: "Additional adjustments")
        expect(subject).to have_css("table tr:nth-child(6) td:nth-child(1)", text: "VAT")
      end
    end

    context "when the statement is for an ITTECF ECTP contract" do
      let(:contract_trait) { :for_ittecf_ectp }

      it "displays the ITTECF ECTP payment overview component" do
        expect(subject).to have_css("table tr:nth-child(1) td:nth-child(1)", text: "ECTs output payment")
        expect(subject).to have_css("table tr:nth-child(2) td:nth-child(1)", text: "Mentors output payment")
        expect(subject).to have_css("table tr:nth-child(3) td:nth-child(1)", text: "Service fee")
        expect(subject).to have_css("table tr:nth-child(4) td:nth-child(1)", text: "ECTs clawbacks")
        expect(subject).to have_css("table tr:nth-child(5) td:nth-child(1)", text: "Mentors clawbacks")
        expect(subject).to have_css("table tr:nth-child(6) td:nth-child(1)", text: "Additional adjustments")
        expect(subject).to have_css("table tr:nth-child(7) td:nth-child(1)", text: "VAT")
      end
    end
  end

  context "when the form has errors" do
    let(:form) { Admin::Finance::AuthorisePaymentForm.new(confirmed: false).tap(&:valid?) }

    it "prefixes the page title with 'Error:'" do
      expect(view.content_for(:page_title)).to start_with("Error:")
    end

    it { is_expected.to have_text "You must have completed all assurance checks" }
  end
end
