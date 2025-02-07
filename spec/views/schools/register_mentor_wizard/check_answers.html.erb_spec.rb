RSpec.describe "schools/register_mentor_wizard/check_answers.html.erb" do
  let(:back_path) { schools_register_mentor_wizard_email_address_path }
  let(:confirm_details_path) { schools_register_mentor_wizard_check_answers_path }
  let(:ect_name) { "Michael Dixon" }
  let(:title) { "Check your answers and confirm mentor details" }
  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "1234567",
                     trs_first_name: "John",
                     trs_last_name: "Wayne",
                     corrected_name: "Jim Wayne",
                     email: "john.wayne@example.com")
  end

  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :check_answers, store:) }
  let(:mentor) { wizard.mentor }

  before do
    assign(:wizard, wizard)
    assign(:ect_name, ect_name)
    assign(:mentor, mentor)
  end

  it "sets the page title to 'Check mentor details'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it 'includes a back button that links to trn and dob page of the journey' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'displays TRN, Name and Email address' do
    render

    expect(rendered).to have_element(:dt, text: "Teacher reference number (TRN)")
    expect(rendered).to have_element(:dd, text: "1234567")
    expect(rendered).to have_element(:dt, text: "Name")
    expect(rendered).to have_element(:dd, text: "Jim Wayne")
    expect(rendered).to have_element(:dt, text: "Email address")
    expect(rendered).to have_element(:dd, text: "john.wayne@example.com")
  end

  it 'includes an inset with the names of the mentor and ECT associated' do
    render

    expect(rendered).to have_selector(".govuk-inset-text", text: 'Jim Wayne will mentor Michael Dixon', visible: true)
    expect(rendered).to have_selector("form[action='#{confirm_details_path}']")
  end

  it 'includes a Confirm details button that posts to the check answers page' do
    render

    expect(rendered).to have_button('Confirm details')
    expect(rendered).to have_selector("form[action='#{confirm_details_path}']")
  end

  it "has change links" do
    render

    expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_mentor_details_path)
    expect(rendered).to have_link("Change", href: schools_register_mentor_wizard_change_email_address_path)
  end
end
