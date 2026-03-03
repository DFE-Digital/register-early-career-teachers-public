RSpec.describe "admin/finance/authorisations/new.html.erb" do
  subject { rendered }

  let(:statement) { Admin::StatementPresenter.new(FactoryBot.create(:statement)) }
  let(:form) { Admin::Finance::AuthorisePaymentForm.new }

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

  it { is_expected.to have_text(statement.lead_provider_name) }
  it { is_expected.to have_text(statement.period) }
  it { is_expected.to have_text(statement.formatted_deadline_date) }
  it { is_expected.to have_text(statement.formatted_payment_date) }
  it { is_expected.to have_field("I confirm I've completed all assurance checks and I authorise payment", type: "checkbox") }
  it { is_expected.to have_button("Authorise for payment") }

  it "shows the total amount for the statement" do
    pending("calculators")
    fail
  end

  describe "summary table" do
    it "needs real figures" do
      pending("calculators")
      fail
    end

    it do
      expect(subject).to have_table with_rows: [
        ["Output payment", 0],
        ["Service fee", 0],
        ["Uplift fees", 0],
        ["Clawbacks", 0],
        ["Additional adjustments", 0],
        ["VAT", 0],
      ]
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
