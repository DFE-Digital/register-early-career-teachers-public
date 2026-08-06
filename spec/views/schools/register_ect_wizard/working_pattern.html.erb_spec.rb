RSpec.describe "schools/register_ect_wizard/working_pattern.html.erb" do
  let(:ect) { wizard.ect }
  let(:store) do
    FactoryBot.build(:session_repository, trs_first_name: "John", trs_last_name: "Smith")
  end
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :working_pattern, store:) }

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "uses the fieldset legend as the page heading to avoid repeating the question for screen readers" do
    render

    question = "Is John Smith’s working pattern as an ECT full or part time?"

    expect(view.content_for(:page_header)).to be_blank
    expect(rendered).to have_css("legend h1", text: question)
  end
end
