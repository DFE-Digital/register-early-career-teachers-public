RSpec.describe "admin/finance/voids/new.html.erb", type: :view do
  subject { Capybara.string(rendered) }

  let(:teacher) { FactoryBot.build_stubbed(:teacher) }
  let(:lead_provider) { FactoryBot.build_stubbed(:lead_provider, name: "Test Lead Provider") }
  let(:delivery_partner) { FactoryBot.build_stubbed(:delivery_partner, name: "Test Delivery Partner") }
  let(:declaration) do
    FactoryBot.build_stubbed(
      :declaration,
      declaration_type: "started",
      declaration_date: Date.new(2024, 1, 15),
      api_id: "test-declaration-uuid",
      evidence_type: "training-event-attended"
    ).tap do |d|
      allow(d).to receive_messages(
        api_id: "test-declaration-uuid",
        lead_provider:,
        delivery_partner_when_created: delivery_partner,
        for_ect?: true,
        for_mentor?: false,
        teacher:,
        overall_status: "eligible"
      )
    end
  end
  let(:void_declaration_form) { Admin::Finance::VoidDeclarationForm.new(declaration:, author: nil) }

  before do
    assign(:declaration, declaration)
    assign(:teacher, teacher)
    assign(:void_declaration_form, void_declaration_form)

    # rubocop:disable RSpec/AnyInstance - needed for boundary with a helper
    allow_any_instance_of(DeclarationHelper).to receive(:declaration_course_identifier).and_return("ecf-induction")
    allow_any_instance_of(TeacherHelper).to receive(:teacher_full_name).and_return("Test Teacher")
    # rubocop:enable RSpec/AnyInstance

    render
  end

  it "sets the page title" do
    expect(view.content_for(:page_title)).to include("Void declaration for Test Teacher")
  end

  it { is_expected.to have_summary_list_row("Declaration ID", value: "test-declaration-uuid", visible: :all) }
  it { is_expected.to have_summary_list_row("Course identifier", value: "ecf-induction", visible: :all) }
  it { is_expected.to have_summary_list_row("Declaration type", value: "started", visible: :all) }
  it { is_expected.to have_summary_list_row("State", value: "Eligible", visible: :all) }
  it { is_expected.to have_summary_list_row("Declaration date and time", value: "15 January 2024, 12:00am", visible: :all) }
  it { is_expected.to have_summary_list_row("Lead provider", value: "Test Lead Provider", visible: :all) }
  it { is_expected.to have_summary_list_row("Evidence held", value: "training-event-attended", visible: :all) }

  describe "delivery partner" do
    context "when the declaration has no delivery partner" do
      let(:delivery_partner) { nil }

      it { is_expected.to have_summary_list_row("Delivery partner", value: "Delivery partner not recorded", visible: :all) }
    end

    context "when the declaration has a delivery partner" do
      it { is_expected.to have_summary_list_row("Delivery partner", value: "Test Delivery Partner", visible: :all) }
    end
  end

  it "has a confirmation checkbox" do
    expect(rendered).to have_field("admin_finance_void_declaration_form[confirmed]", type: "checkbox")
    expect(rendered).to have_content("I confirm I want to void this declaration and I understand that it cannot be undone")
  end

  it "has a warning-styled confirm button" do
    expect(rendered).to have_css("button.govuk-button--warning[type='submit']", text: "Confirm void declaration")
  end

  describe "error state" do
    context "when there is no error" do
      it "does not display an error summary" do
        expect(view.content_for(:error_summary)).to be_blank
      end

      it "does not have error styling on the form group" do
        expect(rendered).not_to have_css(".govuk-form-group--error")
      end
    end

    context "when there is an error" do
      before do
        form_with_errors = Admin::Finance::VoidDeclarationForm.new(declaration:, author: nil, confirmed: "0")
        form_with_errors.valid?
        assign(:void_declaration_form, form_with_errors)
        render
      end

      it "displays an error summary" do
        expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
        expect(view.content_for(:error_summary)).to have_content("There is a problem")
        expect(view.content_for(:error_summary)).to have_link("Confirm you want to void this declaration")
      end

      it "has error styling on the form group" do
        expect(rendered).to have_css(".govuk-form-group--error")
      end

      it "displays the error message by the checkbox" do
        expect(rendered).to have_css(".govuk-error-message", text: "Confirm you want to void this declaration")
      end
    end
  end
end
