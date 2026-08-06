RSpec.describe "schools/register_mentor_wizard/mentoring_at_new_school_only.html.erb" do
  let(:store) do
    FactoryBot.build(:session_repository, trs_first_name: "John", trs_last_name: "Smith")
  end
  let(:wizard) do
    FactoryBot.build(:register_mentor_wizard, current_step: :mentoring_at_new_school_only, store:)
  end
  let(:mentor) { wizard.mentor }

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
  end

  it "uses the fieldset legend as the page heading to avoid repeating the question for screen readers" do
    render

    expect(view.content_for(:page_header)).to be_blank
    expect(rendered).to have_css("legend h1", text: "Will John Smith be mentoring ECTs at your school only?")
  end
end
