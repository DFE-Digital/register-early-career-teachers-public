RSpec.describe "admin/induction_periods/confirm_delete.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Floella", trs_last_name: "Benjamin") }
  let(:back_path) { admin_teacher_induction_path(teacher) }
  let(:induction_period) { FactoryBot.create(:induction_period, teacher:) }

  before do
    assign(:teacher, teacher)
    assign(:induction_period, induction_period)
    assign(:delete_induction, InductionPeriods::DeleteInductionPeriod.new(induction_period:))
  end

  it "renders a warning" do
    render

    expect(view.content_for(:page_title)).to eql("Delete induction period for Floella Benjamin")
    expect(rendered).to have_text("Are you sure you want to delete this induction period?")
    expect(rendered).to have_button("Delete induction period")
  end

  it "includes a back button that links to the ECT admin page" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: back_path)
  end

  it "renders induction types" do
    render

    expect(rendered).to have_text("Provider-led")
  end
end
