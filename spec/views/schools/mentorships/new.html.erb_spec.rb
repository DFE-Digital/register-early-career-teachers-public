RSpec.describe "schools/mentorships/new.html.erb" do
  let(:ect) { create(:ect_at_school_period, :active) }
  let(:ect_name) { Teachers::Name.new(ect.teacher).full_name }
  let(:mentor) { double("mentor_at_school_period", full_name: 'Peter Times', id: 7) }
  let(:mentor_id) { mentor.id }
  let(:mentor_form) { Schools::AssignMentorForm.new(ect:, mentor_id:) }
  let(:title) { "Who will mentor #{ect_name}?" }
  let(:continue_path) { schools_ect_mentorship_path(ect) }
  let(:back_path) { schools_ects_home_path }

  before do
    assign(:ect, ect)
    assign(:ect_name, ect_name)
    assign(:mentor_form, mentor_form)
  end

  it "sets the page title to 'You've assigned <mentor name> as a mentor'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  context "when the mentorship is invalid" do
    let(:mentor_id) { nil }

    before do
      mentor_form.valid?
      render
    end

    it "prefixes the page with 'Error:'" do
      expect(view.content_for(:page_title)).to start_with('Error:')
    end

    it 'renders an error summary' do
      expect(view.content_for(:error_summary)).to have_css('.govuk-error-summary')
    end
  end

  it 'includes a back button that links to the school home page' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the mentorship creation action' do
    render

    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{continue_path}']")
  end
end
