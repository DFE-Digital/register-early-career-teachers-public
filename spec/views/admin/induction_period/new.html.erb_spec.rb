RSpec.describe "admin/induction_periods/new.html.erb" do
  let(:ect) { FactoryBot.create(:ect_at_school_period, :ongoing) }
  let(:back_path) { admin_teacher_path(ect.teacher) }
  let(:induction_period) { FactoryBot.build(:induction_period, teacher: ect.teacher) }

  before do
    assign(:induction_period, induction_period)
    assign(:teacher, ect.teacher)
  end

  it "includes a back button that links to the ECT admin page" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: back_path)
  end

  it "renders induction types" do
    render

    expect(rendered).to have_text("Provider-led")
    expect(rendered).to have_text("School-led")
  end
end
