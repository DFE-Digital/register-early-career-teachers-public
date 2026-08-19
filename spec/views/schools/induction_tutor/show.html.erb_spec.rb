RSpec.describe "schools/induction_tutor/show.html.erb" do
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }

  before do
    assign(:school, school)
    render
  end

  it "renders the induction tutor details as a h2" do
    expect(rendered).to have_css("h2", text: "Induction tutor details")
  end
end
